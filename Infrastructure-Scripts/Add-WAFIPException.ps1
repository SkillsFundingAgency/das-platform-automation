<#
    .SYNOPSIS
    Add a custom rule to whitelist an IP address on the WAF

    .DESCRIPTION
    Add a custom rule to whitelist an IP address on the WAF

    .PARAMETER ResourceGroupName
    Name of the resource group

    .PARAMETER PolicyName
    Name of the Web Application Firewall policy

    .PARAMETER IPAddress
    An IP address to add to the ip range filter

    .PARAMETER Name
    Name of the user who will whitelist their IP

    .EXAMPLE
    Add-WAFIPException -Name JoeBlogs -IPAddress 192.168.0.1 -PolicyName daspolicy -ResourceGroupName rgname
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$Name,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IPAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$PolicyName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ResourceGroupName
)

# Get the WAF policy
$WafPolicy = Get-AzApplicationGatewayFirewallPolicy -Name $PolicyName -ResourceGroupName $ResourceGroupName

# Creates a match variable for firewall condition and a match condition for custom rule
$MatchVariable = New-AzApplicationGatewayFirewallMatchVariable -VariableName "RemoteAddr"

$MatchCondition = New-AzApplicationGatewayFirewallCondition -MatchVariable $MatchVariable -Operator IPMatch -MatchValue $IPAddress

# Check if the IP address already exists in the WAF whitelist
foreach ($IP in $Wafpolicy.CustomRules.MatchConditions.MatchValues) {
    if ($IP -contains $IPAddress) {
        $IPExists = $true
    }
    else {
        $IPExists = $false
    }
}

# Workout which priority the custom rule should be
$StartPriority = 1
$CurrentHighestPriority = ($WafPolicy.CustomRules | Measure-Object -Property Priority -Maximum).Maximum

if (!$WafPolicy.CustomRules) {
    $NewPriority = $StartPriority
}
else {
    $NewPriority = $CurrentHighestPriority + 1
}

# Create a new custom rule with the match condition set above and allow action
$CustomRule = New-AzApplicationGatewayFirewallCustomRule -Name $Name -Priority $NewPriority -RuleType MatchRule -MatchCondition $MatchCondition -Action Allow
try {
    # Add the IP address to the WAF whitelist if it doesn't already exist
    if ($IPExists) {
        Write-Host "The IP address $IPAddress is already in the WAF whitelist."
    } 
    else {
        $WafPolicy.CustomRules.Add($CustomRule)
        Set-AzApplicationGatewayFirewallPolicy -InputObject $WafPolicy
        Write-Host "The IP address $IPAddress has been added to the WAF whitelist."
    }
}
catch {
    throw "Failed to add firewall exception: $_"
}
