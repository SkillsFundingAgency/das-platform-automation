<#
    .SYNOPSIS
    Remove the whitelisted IP from the SQL Server firewall rule
    .DESCRIPTION
    Remove the whitelisted IP from the SQL firewall rule
    .PARAMETER Name
    The name of the firewall rule
    .PARAMETER IPAddress
    The whitelisted IP Address that will get removed by this script
    .PARAMETER  ResourceNamePattern
    Substring of the SQL Server to search for
    .EXAMPLE
    Remove-AzureSQLIPException -Name rulename -IPAddress $(IPAddress) -ResourceNamePatterb das-*
#>
[CmdletBinding()]
param(
    [ValidateNotNull()]
    [IPAddress]$IPAddress,
    [ValidateNotNull()]
    [Parameter(Mandatory = $true)]
    [string]$ResourceNamePattern,
    [ValidateNotNull()]
    [Parameter(Mandatory = $true)]
    [string]$Name
)

$SubscriptionSqlServers = Get-AzResource -Name $ResourceNamePattern -ResourceType "Microsoft.Sql/Servers"

foreach($SqlServer in $SubscriptionSqlServers) {
    $ResourceGroupName = $SqlServer.ResourceGroupName
    $ServerName = $SqlServer.Name
}

if ($SubscriptionSqlServers) {

    $FirewallRuleParameters = @{
        ResourceGroupName = $ResourceGroupName
        ServerName = $ServerName
        FirewallRuleName = $Name
    }

}

$FirewallRules = Get-AzSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ResourceGroupName | Where-Object {$_.StartIpAddress -eq $IPAddress}

if (!$FirewallRules) {
    throw " -> Could not find whitelisted $IPAddress to remove!"
}
else {
    Write-Output "  -> Removing $IPAddress"
    Remove-AzSqlServerFirewallRule  @FirewallRuleParameters
    Write-Output "  -> $IPAddress, removed!"
}
