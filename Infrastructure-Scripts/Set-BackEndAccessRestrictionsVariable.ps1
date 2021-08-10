<#
    .SYNOPSIS
    Ran in Azure DevOps pipeline before ARM template deployment task.
    Creates a BackEndAccessRestrictions Azure DevOps variable.

    .DESCRIPTION
    Ran in Azure DevOps pipeline before ARM template deployment task.
    Gets current subnets in environment's virtual network, excludes BackEndAccessRestrictionsExcludedSubnets, combines with UptimeMonitoringAccessRestrictions.
    Converts to an array of IpSecurityRestriction objects https://docs.microsoft.com/en-us/azure/templates/microsoft.web/sites?tabs=json#IpSecurityRestriction
    Outputs array to BackEndAccessRestrictions Azure DevOps variable for use in later ARM template deployment task.

    .PARAMETER SharedEnvResourceGroup
    The name of the shared resource group that contains the shared virtual network.

    .PARAMETER SharedEnvVirtualNetworkName
    The name of the shared virtual network.

    .PARAMETER BackEndAccessRestrictionsExcludedSubnets
    The array of subnets to exclude from the BackEndAccessRestrictions outputted variable.
    E.g. foo-sn,bar-sn

    .PARAMETER UptimeMonitoringAccessRestrictions
    The array of the name / IP address objects to allow for uptime monitoring. The IP addresses can be public or private.
    E.g. @(@{name="UptimeMonitor"; ipAddress="10.0.0.0/32"})

    .EXAMPLE
    .\Set-BackEndAccessRestrictionsVariable.ps1 -SharedEnvResourceGroup foo-rg -SharedEnvVirtualNetworkName foo-vnet -BackEndAccessRestrictionsExcludedSubnets foo-sn,bar-sn -UptimeMonitoringAccessRestrictions @(@{name="UptimeMonitor"; ipAddress="10.0.0.0/32"})
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$SharedEnvResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$SharedEnvVirtualNetworkName,
    [Parameter(Mandatory = $true)]
    [String[]]$BackEndAccessRestrictionsExcludedSubnets,
    [Parameter(Mandatory = $false)]
    [Array]$UptimeMonitoringAccessRestrictions = @()
)

$SubscriptionId = (Get-AzSubscription).Id

$Subnets = (Get-AzVirtualNetwork -Name $SharedEnvVirtualNetworkName -ResourceGroupName $SharedEnvResourceGroup).Subnets.Name | Where-Object {$_ -notin $BackEndAccessRestrictionsExcludedSubnets} | Sort-Object

$AllowedSubnetsArray = @()

foreach ($Subnet in $Subnets) {
    $AllowedSubnetObject = New-Object PSObject
    $AllowedSubnetObject | Add-Member -NotePropertyMembers @{
        vnetSubnetResourceId = "/subscriptions/$($SubscriptionId)/resourceGroups/$($SharedEnvResourceGroup)/providers/Microsoft.Network/virtualNetworks/$($SharedEnvVirtualNetworkName)/subnets/$($Subnet)"
        name                 = $Subnet
    }
    $AllowedSubnetsArray += $AllowedSubnetObject
}

$BackEndAccessRestrictionsArray = $AllowedSubnetsArray + $UptimeMonitoringAccessRestrictions

$Priority = 100

foreach ($BackEndAccessRestrictionObject in $BackEndAccessRestrictionsArray) {
    $BackEndAccessRestrictionObject | Add-Member -NotePropertyMembers @{
        action   = "Allow"
        priority = $Priority
    }
    $Priority++
}

$BackEndAccessRestrictionsArray

Write-Output "Setting value of BackEndAccessRestrictionsArray variable to BackEndAccessRestrictions pipeline variable"
Write-Output "##vso[task.setvariable variable=BackEndAccessRestrictions]$BackEndAccessRestrictionsArray"
