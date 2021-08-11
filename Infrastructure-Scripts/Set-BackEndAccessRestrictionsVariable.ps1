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

    .PARAMETER ResourceEnvironmentName
    The resource environment name
    E.g. foo

    .PARAMETER UnrestrictedEnvironments
    The array of resource environment names for environments to have an empty array for BackEndAccessRestrictions outputted variable and therefore no access restrictions.
    E.g. foo,bar

    .PARAMETER UptimeMonitoringAccessRestrictions
    The array of the name / IP address objects to allow for uptime monitoring. The IP addresses can be public or private.
    E.g. @(@{name="UptimeMonitor"; ipAddress="10.0.0.0/32"})

    .EXAMPLE
    .\Set-BackEndAccessRestrictionsVariable.ps1 -SharedEnvResourceGroup foo-rg -SharedEnvVirtualNetworkName foo-vnet -BackEndAccessRestrictionsExcludedSubnets foo-sn,bar-sn -ResourceEnvironmentName foo -UnrestrictedEnvironments foo,bar -UptimeMonitoringAccessRestrictions @(@{name="UptimeMonitor"; ipAddress="10.0.0.0/32"})
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$SharedEnvResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$SharedEnvVirtualNetworkName,
    [Parameter(Mandatory = $true)]
    [String[]]$BackEndAccessRestrictionsExcludedSubnets,
    [Parameter(Mandatory = $true)]
    [String]$ResourceEnvironmentName,
    [Parameter(Mandatory = $true)]
    [String[]]$UnrestrictedEnvironments,
    [Parameter(Mandatory = $false)]
    [String]$UptimeMonitoringAccessRestrictions = "[]"
)

try {
    if ($ResourceEnvironmentName -in $UnrestrictedEnvironments) {
        $BackEndAccessRestrictionsArrayJson = "[]"
    }
    else {
        $AllowedSubnetsArray = @()

        $SubscriptionId = (Get-AzSubscription).Id

        $VirtualNetwork = (Get-AzVirtualNetwork -Name $SharedEnvVirtualNetworkName -ResourceGroupName $SharedEnvResourceGroup)

        if (!$VirtualNetwork) {
            throw "Could not find a virtual network matching $SharedEnvVirtualNetworkName and $SharedEnvResourceGroup in the subscription"
        }

        $Subnets = $VirtualNetwork.Subnets.Name | Where-Object {$_ -notin $BackEndAccessRestrictionsExcludedSubnets} | Sort-Object

        foreach ($Subnet in $Subnets) {
            $AllowedSubnetObject = New-Object PSObject
            $AllowedSubnetObject | Add-Member -NotePropertyMembers @{
                vnetSubnetResourceId = "/subscriptions/$($SubscriptionId)/resourceGroups/$($SharedEnvResourceGroup)/providers/Microsoft.Network/virtualNetworks/$($SharedEnvVirtualNetworkName)/subnets/$($Subnet)"
                name                 = $Subnet
            }
            $AllowedSubnetsArray += $AllowedSubnetObject
        }

        try {
            $UptimeMonitoringAccessRestrictionsJson = ConvertFrom-Json ($UptimeMonitoringAccessRestrictions -Replace '\\"','"')
        }
        catch {
            throw "Could not convert invalid JSON of UptimeMonitoringAccessRestrictions parameter"
        }

        $BackEndAccessRestrictionsArray = $AllowedSubnetsArray + $UptimeMonitoringAccessRestrictionsJson

        $Priority = 100

        foreach ($BackEndAccessRestrictionObject in $BackEndAccessRestrictionsArray) {
            $BackEndAccessRestrictionObject | Add-Member -NotePropertyMembers @{
                action   = "Allow"
                priority = $Priority
            }
            $Priority++
        }

        $BackEndAccessRestrictionsArrayJson = ConvertTo-Json $BackEndAccessRestrictionsArray -Compress
    }

    Write-Output "Setting value of BackEndAccessRestrictionsArrayJson variable to BackEndAccessRestrictions pipeline variable"
    Write-Output "##vso[task.setvariable variable=BackEndAccessRestrictions]$BackEndAccessRestrictionsArrayJson"
}
catch {
    throw "$_"
}
