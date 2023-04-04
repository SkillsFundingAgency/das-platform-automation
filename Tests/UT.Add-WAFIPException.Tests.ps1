Describe "Add IP address to WAF whitelist" {
    Context " Check if Web Application Firewall exists" {
        It 'should return a firewall policy' {
            $Policy = @{
                ResourceGroupName = 'myResourceGroup'
                PolicyName = 'myPolicy'
            }

            Mock Get-AzApplicationGatewayFirewallPolicy -MockWith { return $Policy }

            $WafPolicy = Get-AzApplicationGatewayFirewallPolicy
        
            $WafPolicy | Should Not Be $null
        }
    }

    Context "Check for users IP address" {
        It "does exist" {
            $WafPolicy = [PSCustomObject]@{
                CustomRules = [PSCustomObject]@{
                    MatchCondition = [PSCustomObject]@{
                        MatchValues = @('192.168.0.10', '10.0.0.1')
                    }
                }
            }
            
            $IPAddress = '10.0.0.1'

            $IPExists = $WafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }
            
            $IPExists | Should Be $true
        }
        It "does not exist" {
            $WafPolicy = [PSCustomObject]@{
                CustomRules = [PSCustomObject]@{
                    MatchCondition = [PSCustomObject]@{
                        MatchValues = @('192.168.0.10', '10.0.0.1')
                    }
                }
            }
            
            $IPAddress = '192.158.0.1'

            $IPExists = $WafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }
            
            $IPExists | Should Not Be $true
        }
    }
    context "Check which priority custom rule should be set as" {
        $StartPriority = 1
        it "sets the new priority as the starting priority" {
            $WafPolicy = $null
            $NewPriority = if (!$WafPolicy.CustomRules) {
            $StartPriority
            }

            $NewPriority | Should Be 1
        }
        it "sets the new priority as the next highest priority" {
            $WafPolicy = [pscustomobject]@{
                CustomRules = @([pscustomobject]@{ Priority = 1},[pscustomobject]@{ Priority = 2})
            }

            $CurrentHighestPriority = ($WafPolicy.CustomRules | Measure-Object -Property Priority -Maximum).Maximum
            $NewPriority = if ($WafPolicy.CustomRules) {
                $CurrentHighestPriority + 1
            }
            $NewPriority | Should Be 3
        }
    }
    Context "Creation of custom rule" {
        $NewCustomRule = @{
            Name = 'test'
            Priority = '3'
            RuleType = 'MatchRule'
            MatchCondition = 'MatchCondition'
            Action = 'Allow'
        }
            Mock New-AzApplicationGatewayFirewallCustomRule -MockWith { return $NewCustomRule }

        It 'should create a custom rule' {
            $CustomRule = Get-AzApplicationGatewayFirewallPolicy
        
            $CustomRule | Should Not Be $null
        }
        It 'should add a new custom rule' {
            $IPExists = $null
            $WafPolicy.CustomRules = $null
            $CustomRuleCreated = if ($IPExists) {
            $WafPolicy.CustomRules += New-AzApplicationGatewayFirewallCustomRule
            }
            $CustomRuleCreated | Should Not Be NullOrEmpty
        }
        It 'should not add a new custom rule' {
            $IPExists = $null
            $WafPolicy.CustomRules = $null
            $CustomRuleCreated = if (!$IPExists) {
            $WafPolicy.CustomRules
            }
            $CustomRuleCreated | Should Be $null
        }
    }
}