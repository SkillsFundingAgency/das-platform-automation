<#
    .SYNOPSIS
    Removes an IP address access restriction rule from an app service

    .DESCRIPTION
    Removes an IP address access restriction rule from an app service

    .PARAMETER IpAddress
    An ip address to associate with the access restriction rule

    .PARAMETER ResourceName
    The name of the app service

    .EXAMPLE
    Remove-AppServiceIpException -IpAddress 192.168.0.1 -ResourceName das-foobar
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


$AppServiceResource = Get-AzResource -Name $ResourceName -ResourceType "Microsoft.Web/sites"

if (!$AppServiceResource) {
    throw "Could not find a resource matching $ResourceName in the subscription"
}

$AppServiceWhitelist = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $AppServiceResource.ResourceGroupName -Name $ResourceName | Where-Object { $_.MainSiteAccessRestrictions.IpAddress -eq "$IPAddress/32" }

if (!$AppServiceWhitelist) {
    Write-Output " -> Could not find whitelisted $IPAddress to remove!"
}
else {
    Write-Output "  -> Removing $IPAddress"
    Remove-AzWebAppAccessRestrictionRule  -ResourceGroupName $AppServiceResource.ResourceGroupName -WebAppName $ResourceName -IpAddress "$IPAddress/32"
    Write-Output "  -> $IPAddress, removed!"
}