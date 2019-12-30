<#

    .SYNOPSIS
    Update the access restriction rules for an app service

    .DESCRIPTION
    Update the access restriction rules for an app service

    .PARAMETER IpAddress
    An ip address to associate with the access restriction rule

    .PARAMETER ResourceName
    The name of the app service

    .EXAMPLE
    Add-AppServiceIpException -IpAddress 192.168.0.1 -ResourceName das-prd-sms-as

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IpAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ResourceName
)

try {
    if ($env:RELEASE_ENVIRONMENTNAME == "DEV") {
        $ReleaseName = $env:RELEASE_RELEASENAME.Replace("Name", "$env:RELEASE_REQUESTEDFOR")
        Write-Output "##vso[release.updatereleasename]$ReleaseName"
    }

    $Name = $env:Release_RequestedFor.Replace(' ', '')
    $AppServiceResource = Get-AzResource -Name $ResourceName -ResourceType "Microsoft.Web/sites"

    if (!$AppServiceResource) {
        throw "Could not find a resource matching $ResourceName in the subscription"
    }

    $AppServiceResourceConfig = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $AppServiceResource.ResourceGroupName -Name $ResourceName

    Write-Output "Processing app service: $ResourceName and Creating rule $Name"

    # --- Workout next priority number
    $StartPriority = 100
    $ExistingPriority = ($AppServiceResourceConfig.MainSiteAccessRestrictions.priority | Where-Object { ($_ -ge $StartPriority) -and $_ -lt [int32]::MaxValue } | Measure-Object -Maximum).Maximum

    if (!$ExistingPriority) {
        $NewPriority = $StartPriority
    }
    else {
        $NewPriority = $ExistingPriority + 1
    }

    Write-Output "  -> Rule priority set to $NewPriority"
    Add-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResource.ResourceGroupName -WebAppName $ResourceName -Name $Name -Priority $NewPriority -Action "Allow" -IpAddress "$IpAddress/32"
}
catch {
    throw "$_"
}
