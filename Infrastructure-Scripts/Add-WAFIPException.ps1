# Get the WAF policy
$wafpolicy = Get-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName "das-pp-firewall-rg"


# Check if the IP address already exists in the WAF whitelist
$IPExists = $wafpolicy.CustomRules.Where({ $_.MatchValues -contains $IPAddress })


# Add the IP address to the WAF whitelist if it doesn't already exist
if (!$IPExists) {
    $customRule = New-AzApplicationGatewayFirewallCustomRule -Name "Will" Priority 200 -RuleType MatchRule -MatchValues $IPAddress -Action Allow
    $wafpolicy.CustomRules += $customRule
    Set-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName $ResourceGroupName -CustomRules $wafpolicy.CustomRules
    Write-Host "The IP address $IPAddress has been added to the WAF whitelist."
} else {
    Write-Host "The IP address $IPAddress is already in the WAF whitelist."
}