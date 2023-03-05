<#
    .SYNOPSIS
    Add a custom rule to whitelist an IP address on the WAF
    
    .DESCRIPTION
    Add a custom rule to whitelist an IP address on the WAF

    .PARAMETER IPAddress
    An IP address to add to the ip range filter

    .PARAMETER Name
    Name of the firewall rule

    .PARAMETER Priority
    Priority of the rule
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$resourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IPAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$Name,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$Priority
)

# Get the WAF policy
$policyName = @('dasppsharedfewp', 'dasppsharedbewp')
$wafPolicy = Get-AzApplicationGatewayFirewallPolicy -Name $policyName -ResourceGroupName $resourceGroupName

# Check if the IP address already exists in the WAF whitelist
$IPExists = $wafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }

# Creates a match variable for firewall condition and a match condition for custom rule
$matchVariable = Get-AzApplicationGatewayFirewallMatchVariable -VariableName "RemoteAddr"

$matchCondition = New-AzApplicationGatewayFirewallCondition -MatchVariable $matchVariable -Operator IPMatch -MatchValue $IPAddress

# Create a new custom rule with the match condition set above and allow action
$customRule = New-AzApplicationGatewayFirewallCustomRule -Name $Name -Priority $Priority -RuleType MatchRule -MatchCondition $matchCondition -Action Allow

# Add the IP address to the WAF whitelist if it doesn't already exist
if (!$IPExists) {
    $wafPolicy.CustomRules.Add($customRule)
    Set-AzApplicationGatewayFirewallPolicy -InputObject $wafPolicy
    Write-Host "The IP address $IPAddress has been added to the WAF whitelist."
} else {
    Write-Host "The IP address $IPAddress is already in the WAF whitelist."
}