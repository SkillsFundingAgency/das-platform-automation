<#

    .SYNOPSIS
    Update the firewall of an Azure SQL Server

    .DESCRIPTION
    Update the firewall of an Azure SQL Server

    .PARAMETER IpAddress
    An ip address to associate with the firewall rule

    .PARAMETER ResourceNamePattern
    Substring of the SQL Server to search for

    .EXAMPLE
    Add-AzSqlIpException -IpAddress 192.168.0.1 -ResourceNamePattern das-*

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IpAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ResourceNamePattern
)

try {
    $Name = $env:Release.RequestedFor.Replace(' ', '')
    Write-Output "##vso[build.updatereleasename]Whitelist-$Name-$IpAddress"
    $SubscriptionSqlServers = Get-AzResource -Name $ResourceNamePattern -ResourceType "Microsoft.Sql/Servers"

    if (!$SubscriptionSqlServers) {
        throw "Could not find a resource matching $ResourceNamePattern in the subscription"
    }

    foreach ($SqlServer in $SubscriptionSqlServers) {
        # --- Set Resource Group Name
        $ResourceGroupName = $SqlServer.ResourceGroupName
        $ServerName = $SqlServer.Name

        # --- Create or update firewall rules on the SQL Server instance
        Write-Output "Processing Sql Server $ServerName"
        $FirewallRuleParameters = @{
            ResourceGroupName = $ResourceGroupName
            ServerName        = $ServerName
            FirewallRuleName  = $Name
            StartIpAddress    = $IpAddress
            EndIPAddress      = $IpAddress
        }

        # --- Try to retrieve the firewall rule by name
        $FirewallRule = Get-AzSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ResourceGroupName | Where-Object { $_.FirewallRuleName.ToLower() -eq $Name.ToLower() }

        # --- Create or update the new rule
        if (!$FirewallRule) {
            Write-Output "  -> Creating firewall rule $Name with value $IpAddress"
            $null = New-AzSqlServerFirewallRule @FirewallRuleParameters -ErrorAction Stop
        }
        else {
            Write-Output "  -> Updating firewall rule $Name with value $IpAddress"
            $FirewallRuleParameters.FirewallRuleName = $FirewallRule.FirewallRuleName
            $null = Set-AzSqlServerFirewallRule @FirewallRuleParameters -ErrorAction Stop
        }
    }
}
catch {
    throw "Failed to add firewall exception: $_"
}
