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
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [string]$ServerName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [string]$WhatsMyIpUrl,
    [ValidateNotNull()]
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName = "$env:DeploymentResourceGroup",
    [ValidateNotNull()]
    [Parameter(Mandatory = $true)]
    [string]$Name
)

    # --- Try to retrieve the firewall rule by name
    $FirewallRules = Get-AzSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    $IPAddress = (Invoke-RestMethod $WhatsMyIpUrl -UseBasicParsing)
    $IpRegEx = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
    if ($IPAddress -notmatch $IpRegEx) {
        throw "Unable to retrieve valid IP address using $WhatsMyIpUrl, $IPAddress returned."
    }
    # --- Remove whitelisted Ip Address
    if ($FirewallRules) {
        Write-Verbose "removing whitelisted IP address"
        Remove-AzSqlServerFirewallRule -FirewallRuleName $Name -ServerName $ServerName -ResourceGroupName $ResourceGroupName  -Force -ErrorAction Stop
        Write-Verbose "$IPAddress, removed!"
    }

