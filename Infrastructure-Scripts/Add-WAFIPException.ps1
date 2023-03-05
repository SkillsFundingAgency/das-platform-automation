# Get the WAF policy
$wafpolicy = Get-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName "das-pp-firewall-rg"

# Check if the IP address already exists in the WAF whitelist
$IPExists = $wafpolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }

# Creates a match variable for firewall condition and a match condition for custom rule
$matchVariable = Get-AzApplicationGatewayFirewallMatchVariable -VariableName "RemoteAddr"

$matchCondition = New-AzApplicationGatewayFirewallCondition -MatchVariable $matchVariable -Operator IPMatch -MatchValue $IPAddress

# Create a new custom rule with the match condition set above and allow action
$customRule = New-AzApplicationGatewayFirewallCustomRule -Name $Name -Priority $Priority -RuleType MatchRule -MatchCondition $matchCondition -Action Allow

# Add the IP address to the WAF whitelist if it doesn't already exist
if (!$IPExists) {
    $wafpolicy.CustomRules += $customRule
    Set-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName $ResourceGroupName -CustomRule $wafpolicy.CustomRules
    Write-Host "The IP address $IPAddress has been added to the WAF whitelist."
} else {
    Write-Host "The IP address $IPAddress is already in the WAF whitelist."
}