<#
    .SYNOPSIS
    Checks the status of the HTTP/2 setting for app services and sets to true.

    .DESCRIPTION
    Checks the status of the HTTP/2 setting for app services and sets to true.

    .PARAMETER AppServiceName
    The name of the app service

    .PARAMETER AppServiceResourceGroup
    The resource group containing the app service

    .EXAMPLE
    To see whether a change would be made to a single app service
    Set-AzAppServiceHttp2State.ps1 -AppServiceName das-at-crsdelapi-as -AppServiceResourceGroup das-at-crsdel-rg -WhatIf

#>

[CmdletBinding(DefaultParameterSetName =  "None", SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, ParameterSetName="SingleAppService")]
    $AppServiceName,
    [Parameter(Mandatory = $true, ParameterSetName="SingleAppService")]
    $AppServiceResourceGroup
)

$Resource = Get-AzResource -Name $AppServiceName -ResourceGroupName $AppServiceResourceGroup -ResourceType Microsoft.Web/sites

if ($Resource.Properties.siteConfig.http20Enabled) {
    Write-Verbose "HTTP/2 is enabled for AppServiceName"
}
else {
    Write-Verbose "HTTP/2 is not enabled for AppServiceName, enabling ..."

    if ($PSCmdlet.ShouldProcess($Resource.Name, "Setting HTTP/2 to enabled")) {
        $Resource.Properties.siteConfig.http20Enabled = $true
        $Resource | Set-AzResource -Force | Out-Null
    }
}
