<#
    .SYNOPSIS
    Remove the whitelisted IP from the firewall rule name
    .DESCRIPTION
    Remove the whitelisted IP from the firewall rule name
    .PARAMETER Name
    The name of the firewall rule
    .PARAMETER ServerName
    Name of the Sql server
    .PARAMETER WhatsMyIpUrl
    The url value, "https://ifconfig.me/ip"  that needs to get passed in to identify the IP Address
    .PARAMETER  ResourceGroupName
    The name of the sql server's resource group, defaults to the environment variable DeploymentResourceGroup
    .EXAMPLE
    Remove-AzureSQLIPException -Name rulename -WhatsMyIpUrl "https://ifconfig.me/ip" -ResourceGroupName das-test-rg -Name "rule01"
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
    throw "Could not find whitelisted $IPAddress to remove"
}
else {
    Write-Output "  -> Removing $IPAddress"
    Remove-AzSqlServerFirewallRule  @FirewallRuleParameters
}
