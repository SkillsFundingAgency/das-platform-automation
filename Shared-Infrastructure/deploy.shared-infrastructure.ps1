[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$EnvironmentNames,
    [Parameter(Mandatory = $false)]
    [string]$Location = "West Europe",
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionAbbreviation,
    [Parameter(Mandatory = $false)]
    [string]$DeploymentStorageAccountName = "dasarmdeployments",
    [Parameter(Mandatory = $false)]
    [string]$DeploymentStorageAccountContainer = "sharedinfrastructure",
    [Parameter(Mandatory = $true)]
    [bool]$NetworkingEnabled
)

$ParameterValidationExemptions = "aseHostingEnvironmentName", "aseResourceGroup", "templateSASToken"

try {

    # --- Are We Logged in?
    $IsLoggedIn = (Get-AzureRMContext -ErrorAction SilentlyContinue).Account
    if (!$IsLoggedIn) {
        throw "You are not logged in. Run Add-AzureRmAccount to continue"
    }

    # --- Create Resource Group for Environments
    foreach ($Environment in $EnvironmentNames) {
        $ResourceGroupName = "das-$Environment-shared-rg".ToLower()
        Write-Host "- Creating Resource Group: $ResourceGroupName"
        $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
        if (!$ResourceGroup) {
            $null = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Confirm:$false
        }
    }

    $DatabaseConfiguration = @{}
    Write-Host "- Setting up failover group config"
    # --- Get environment databases for failover group
    foreach ($Environment in $EnvironmentNames) {
        $DatabaseConfiguration += @{$Environment =@{"DatabaseResourceIds" = @()}}

        # Get all shared SQL Servers in environment
        $SqlServerResources = @(Get-AzureRmResource -Name "das-$($Environment.ToLower())-shared-sql*" -ResourceType "Microsoft.Sql/servers")

        # If there is more than one then find the primary
        if ($SqlServerResources.Count -gt 1) {
            $SqlServer = $SqlServerResources | Where-Object {
                $FailoverGroup = Get-AzureRmSqlDatabaseFailoverGroup -ServerName $_.Name -ResourceGroupName $_.ResourceGroupName
                if ($FailoverGroup -and $FailoverGroup.ReplicationRole -eq "Primary") {
                    return $_
                }
            }
        }
        elseif ($SqlServerResources -eq 1) {
            # If there is only one, use that
            $SqlServer = $SqlServerResources[0]
        }
        else {
            continue
        }

        # Get all the databases in the server that aren't master
        $Databases = Get-AzureRmSqlDatabase -ServerName $SqlServer.Name -ResourceGroupName $SqlServer.ResourceGroupName | Where-Object { $_.DatabaseName -ne "master" }

        $DatabaseConfiguration.$Environment.DatabaseResourceIds = @($Databases.ResourceId)
        Write-Host "    - Adding $($Databases.Count) databases to $Environment failover group"
    }

    # --- Set Template parameters
    $ParametersPath = "$PSScriptRoot\Subscription\parameters.json"
    $Parameters = Get-Content -Path $ParametersPath -Raw | ConvertFrom-Json

    $Parameters.parameters.SubscriptionAbbrv.value = $SubscriptionAbbreviation.ToLower()
    $Parameters.parameters.Environments.value = $EnvironmentNames
    $Parameters.parameters.TemplateBaseUrl.value = "https://$DeploymentStorageAccountName.blob.core.windows.net/$DeploymentStorageAccountContainer"
    $Parameters.parameters.DatabaseConfiguration.value = $DatabaseConfiguration
    $Parameters.parameters.NetworkingEnabled.value = $NetworkingEnabled

    # --- Check parameters are populated
    foreach ($property in $Parameters.parameters.PSObject.Properties.name) {
        if ((([string]::IsNullOrEmpty($Parameters.parameters.$property.value)) -or ($Parameters.parameters.$property.value -eq $null)) `
                -and !($ENV:TF_BUILD) -and !($ParameterValidationExemptions.Contains($property))) {
            throw "$property is not populated"
        }
    }

    $null = Set-Content -Path $ParametersPath -Value ([Regex]::Unescape(($Parameters | ConvertTo-Json -Depth 10))) -Force

    $DeploymentParameters = @{
        ResourceGroupName    = "das-$SubscriptionAbbreviation-mgmt-rg".ToLower()
        StorageAccountName   = $DeploymentStorageAccountName
        TemplateLocation     = "$PSScriptRoot\Subscription"
        StorageContainerName = $DeploymentStorageAccountContainer
        ProtectWithSASToken  = $true
    }

    . "$PSScriptRoot\..\Invoke-Deployment.ps1" @DeploymentParameters
}
catch {
    throw "$_"
}
