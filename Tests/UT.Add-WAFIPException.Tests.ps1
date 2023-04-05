Describe "Add IP address to WAF whitelist" {
    Context " Check if Web Application Firewall exists" {
        It 'should return a firewall policy' {
            $Policy = @{
                ResourceGroupName = 'myResourceGroup'
                PolicyName = 'myPolicy'
            }
            Mock Get-AzApplicationGatewayFirewallPolicy -MockWith { return $Policy } | Should Not Be NullOrEmpty
        }
    }

    Context "Check for users IP address" {
        $WafPolicy = @{
            CustomRules = @{
                MatchCondition = @{
                    MatchValues = @('192.168.0.10', '10.0.0.1')
                }
            }
        }
        It "does exist" {
            $IPAddress = '10.0.0.1'

            $IPExists = $WafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }

            $IPExists | Should Be $true
        }
        It "does not exist" {
            $IPAddress = $null

            $IPExists = $WafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }

            $IPExists | Should Not Be $true
        }
    }

    context "Check which priority custom rule should be set as" {
        it "sets the new priority as the starting priority" {
            $WafPolicy = @{
                CustomRules = @()
            }
            $StartPriority = 1
            if ($WafPolicy.CustomRules.Count -eq 0) {
                $NewPriority = $StartPriority
            }
            $NewPriority | Should Be 1
        }
        it "sets the new priority as the next highest priority" {
            $WafPolicy = @{
                CustomRules = @(
                    @{ Priority = 1},
                    @{ Priority = 2}
                )
            }

            $CurrentHighestPriority = ($WafPolicy.CustomRules | Measure-Object -Property Priority -Maximum).Maximum
            if ($WafPolicy.CustomRules) {
                $NewPriority = $CurrentHighestPriority + 1
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
        It 'should create a custom rule' {
            Mock New-AzApplicationGatewayFirewallCustomRule -MockWith { return $NewCustomRule } | Should Not Be NullOrEmpty
        }
        It 'should add a new custom rule' {
            $WafPolicy = @{
                CustomRules = @()
            }
            $IPExists = $null
            $CustomRuleCreated = if ($IPExists) {
            $WafPolicy.CustomRules += $NewCustomRule
            }
            $CustomRuleCreated | Should Not Be NullOrEmpty
        }
        It 'should not add a new custom rule' {
            $WafPolicy = @{
                CustomRules = @()
            }
            $IPExists = $null
            $CustomRuleCreated = if (!$IPExists) {
            $WafPolicy.CustomRules
            }
            $CustomRuleCreated | Should Be $null
        }
    }
}
