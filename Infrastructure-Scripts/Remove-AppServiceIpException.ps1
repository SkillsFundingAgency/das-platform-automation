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
    Remove-AppServiceIpException -IPAddress 192.168.0.1 -ResourceName das-foobar
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IPAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String[]]$ResourceName
)

foreach ($Resource in $ResourceName){

    $AppServiceResource = Get-AzResource -Name $Resource -ResourceType "Microsoft.Web/sites"

    if (!$AppServiceResource) {
        throw "Could not find a resource matching $Resource in the subscription"
    }

    $AppServiceWhitelist = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $AppServiceResource.ResourceGroupName -Name $Resource | Where-Object { $_.MainSiteAccessRestrictions.IpAddress -eq "$IPAddress/32" }

    if (!$AppServiceWhitelist) {
        Write-Output " -> Could not find whitelisted $IPAddress to remove on $Resource!"
    }
    else {
        Write-Output "  -> Removing $IPAddress from $Resource"
        Remove-AzWebAppAccessRestrictionRule  -ResourceGroupName $AppServiceResource.ResourceGroupName -WebAppName $Resource -IpAddress "$IPAddress/32"
        Write-Output "  -> $IPAddress, removed from $Resource!"
    }
}