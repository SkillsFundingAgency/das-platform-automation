<#
.SYNOPSIS
Shared infrastructure deployment helper

.DESCRIPTION
Pre deployment script for shared infrastructure deployments. It is deisnged to be ran in the context of a
build agent or from a local machine.

Build agent deployments:
    * This script only prepares the deployment environment
    * Ensure that the correct template environment variables are present in the release definition
    * Use the ARM template deployment task
    * Secret variables must be passed as override parameters to the ARM tepmlate deployment release task
Local deployments:
    * ONLY to be used for testing and NOT against any environments that are in service
    * The script looks for matching environment variables. If they are not present you will be prompted to enter the values
    * When not in the context of a build server, this script will create the deployment.

.PARAMETER SubscriptionAbbreviation
Abbreviation of the subscription. It is possible for a subscription to have many environments, for example,
a development subscription can contain many development environments.

Default: DEV

.PARAMETER EnvironmentNames
A JSON array of environments to create in a subscription. For example:
"["AT","TEST""]

Default: $ENV:EnvironmentNames

.PARAMETER Location
The location of the resources.

Default: West Europe

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("DEV", "PP", "PRD", "MO")]
    [string]$SubscriptionAbbreviation = "DEV",
    [Parameter(Mandatory = $false)]
    [ValidateSet("AT", "TEST", "TEST2", "DEMO", "PP", "PRD", "MO")]
    [string[]]$EnvironmentNames = ($ENV:EnvironmentNames | ConvertFrom-Json),
    [Parameter(Mandatory = $false)]
    [ValidateSet("West Europe", "North Europe")]
    [string]$Location = "West Europe",
    [Parameter(Mandatory = $false)]
    [switch]$AcceptDefaults
)

$TemplateFilePath = "$PSScriptRoot/templates/subscription.template.json"
$TemplateParametersFilePath = "$PSScriptRoot/templates/subscription.parameters.json"

try {
    # --- Are We Logged in?
    $IsLoggedIn = (Get-AzureRmContext -ErrorAction SilentlyContinue).Account
    if (!$IsLoggedIn) {
        throw "You are not logged in. Run Add-AzureRmAccount to continue"
    }

    # --- Create Resource Groups
    $ManagementResourceGroupName = "das-$SubscriptionAbbreviation-mgmt-rg".ToLower()
    $ResourceGroupList = [System.Collections.ArrayList]::new(@($ManagementResourceGroupName))
    $ResourceGroupList.AddRange(@($EnvironmentNames | ForEach-Object { "das-$_-shared-rg".ToLower() }))

    $ResourceGroupList | ForEach-Object {
        Write-Host "- Creating Resource Group: $_"
        $ResourceGroup = Get-AzureRmResourceGroup -Name $_ -Location $Location -ErrorAction SilentlyContinue
        if (!$ResourceGroup) {
            $null = New-AzureRmResourceGroup -Name $_ -Location $Location -Confirm:$false
        }
    }

    $DatabaseConfiguration = @{ }
    Write-Host "- Setting up failover group config"
    # --- Get environment databases for failover group
    foreach ($Environment in $EnvironmentNames) {
        $DatabaseConfiguration.Add(
            $Environment, @{"DatabaseResourceIds" = @() }
        )

        # --- Get all shared SQL Servers in environment
        $SqlServerResources = @(Get-AzureRmResource -Name "das-$($Environment.ToLower())-shared-sql*" -ResourceType "Microsoft.Sql/servers")

        # --- If there is more than one then find the primary
        if ($SqlServerResources.Count -gt 1) {
            $SqlServer = $SqlServerResources | Where-Object {
                $FailoverGroup = Get-AzureRmSqlDatabaseFailoverGroup -ServerName $_.Name -ResourceGroupName $_.ResourceGroupName
                if ($FailoverGroup -and $FailoverGroup.ReplicationRole -eq "Primary") {
                    return $_
                }
            }
        }
        elseif ($SqlServerResources -eq 1) {
            # --- If there is only one, use that
            $SqlServer = $SqlServerResources[0]
        }
        else {
            continue
        }

        # --- Get all the databases in the server that aren't master
        $Databases = Get-AzureRmSqlDatabase -ServerName $SqlServer.Name -ResourceGroupName $SqlServer.ResourceGroupName | Where-Object { $_.DatabaseName -ne "master" }

        $DatabaseConfiguration.$Environment.DatabaseResourceIds = @($Databases.ResourceId)
        Write-Host "    - Adding $($Databases.Count) databases to $Environment failover group"
    }

    $ENV:DatabaseConfiguration = $DatabaseConfiguration | ConvertTo-Json

    # --- Set Template parameters
    Write-Host "- Building deployment parameters file"
    $ParametersFile = [PSCustomObject]@{
        "`$schema"     = "http://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#"
        contentVersion = "1.0.0.0"
        parameters     = @{ }
    }

    $TemplateParameters = (Get-Content -Path $PSScriptRoot/templates/subscription.template.json -Raw | ConvertFrom-Json).parameters
    foreach ($Property in $TemplateParameters.PSObject.Properties.Name) {
        $ParameterEnvironmentVariableName = $TemplateParameters.$Property.metadata.environmentVariable
        $ParameterEnvironmentVariableType = $TemplateParameters.$Property.type

        if (!$ParameterEnvironmentVariableName -and ($ParameterEnvironmentVariableType -ne "securestring")) {
            throw "Could not find environment variable for template parameter $Property"
        }

        $ParameterVariableValue = Get-Item -Path "ENV:$ParameterEnvironmentVariableName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Value

        if (!$ParameterVariableValue) {
            if (!$ENV:TF_BUILD) {
                if (($TemplateParameters.$Property.defaultValue -or ($TemplateParameters.$Property.defaultValue -ge 0)) -and $AcceptDefaults.IsPresent ) {
                    $ParameterVariableValue = $TemplateParameters.$Property.defaultValue
                }
                else {
                    $ParameterVariableValue = Read-Host -Prompt "   -> [$($ParameterEnvironmentVariableType)] $($ParameterEnvironmentVariableName)"
                }
            }
            elseif ($ParameterEnvironmentVariableType -ne "securestring") {
                throw "Could not find environment variable value for template parameter $Property"
            }
        }

        switch ($ParameterEnvironmentVariableType) {
            'array' {
                $ParameterVariableValue = [String[]]($ParameterVariableValue | ConvertFrom-Json)
                break
            }
            'int' {
                $ParameterVariableValue = [Int]$ParameterVariableValue
                break
            }
            'object' {
                $ParameterVariableValue = $ParameterVariableValue | ConvertFrom-Json
                break
            }
            "default" {
                Write-Warning -Message "Unknown type $ParameterEnvironmentVariableType"
            }
        }

        $ParametersFile.parameters.Add($Property, @{ value = $ParameterVariableValue })
    }

    $null = Set-Content -Path $TemplateParametersFilePath -Value ([Regex]::Unescape(($ParametersFile | ConvertTo-Json -Depth 10))) -Force
    Write-Host "- Parameter file content saved to $TemplateParametersFilePath"

    if (!$ENV:TF_BUILD ) {
        Write-Host "- Deploying $TemplateFilePath"
        $DeploymentParameters = @{
            ResourceGroupName       = $ManagementResourceGroupName
            TemplateParameterFile   = $TemplateParametersFilePath
            TemplateFile            = $TemplateFilePath
            DeploymentDebugLogLevel = "All"
        }
        New-AzureRmResourceGroupDeployment @DeploymentParameters
    }
}
catch {
    throw $_.Exception
}
