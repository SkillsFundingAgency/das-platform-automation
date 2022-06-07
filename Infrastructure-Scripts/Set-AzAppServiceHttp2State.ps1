<#
    .SYNOPSIS
    Checks the status of the HTTP/2 setting for app services and sets to true.

    .DESCRIPTION
    Checks the status of the HTTP/2 setting for app services and sets to true.  Can select a subset of all the app services for a subsciption using AppServiceNamePrefix or be passed
    the name and resource group for a single app service.

    .PARAMETER AppServiceName
    The name of the app service

    .PARAMETER AppServiceResourceGroup
    The resource group containing the app service

    .PARAMETER AppServiceNamePrefix
    A filter to select a subset of the app services in a subscription

    .EXAMPLE
    To see whether a change would be made to a single app service
    Set-AzAppServiceHttp2State.ps1 -AppServiceName das-at-crsdelapi-as -AppServiceResourceGroup das-at-crsdel-rg -WhatIf

    .EXAMPLE
    To see which app services would be changed in a subscription
    Set-AzAppServiceHttp2State.ps1 AppServiceNamePrefix "das-at-" -WhatIf
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "Known bug - https://github.com/PowerShell/PSScriptAnalyzer/issues/1472")]
[CmdletBinding(DefaultParameterSetName =  "None", SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory=$true, ParameterSetName="SingleAppService")]
    [string]$AppServiceName,
    [Parameter(Mandatory=$true, ParameterSetName="SingleAppService")]
    [string]$AppServiceResourceGroup,
    [Parameter(Mandatory=$true, ParameterSetName="Subscription")]
    [string]$AppServiceNamePrefix
)

Begin {
    if ($PSCmdlet.ParameterSetName -eq "Subscription") {
        $AppServices = Get-AzWebApp | Where-Object { $_.Name -match "^$AppServiceNamePrefix.+" }
    }
    elseif ($PSCmdlet.ParameterSetName -eq "SingleAppService") {
        $AppService = New-Object -TypeName PSCustomObject -Property @{ Name = $AppServiceName; ResourceGroup = $AppServiceResourceGroup }
        $AppServices = @($AppService)
    }
}

Process {
    foreach ($AppService in $AppServices) {
        $Resource = Get-AzResource -Name $AppService.Name -ResourceGroupName $AppService.ResourceGroup -ResourceType Microsoft.Web/sites

        if ($Resource.Properties.siteConfig.http20Enabled) {
            Write-Verbose "HTTP/2 is enabled for $($AppService.Name)"
        }
        else {
            Write-Verbose "HTTP/2 is not enabled for $($AppService.Name), enabling ..."

            if ($PSCmdlet.ShouldProcess($Resource.Name, "Setting HTTP/2 to enabled")) {
                $Resource.Properties.siteConfig.http20Enabled = $true
                $Resource | Set-AzResource -Force | Out-Null
            }
        }
    }
}
