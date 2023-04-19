$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-WAFIPException Unit Tests" -Tags @("Unit") {

    $Params = @{
        Name              = "TestUser"
        IPAddress         = $Config.ipAddress
        PolicyName        = $Config.resourceName
        ResourceGroupName = $Config.resourceGroupName
    }

    Context "Web Application Firewall policy does not exist" {
        It 'The specified Resource was not found in the resource group, throw an error' {
            Mock Get-AzApplicationGatewayFirewallPolicy -MockWith { return $null }
            { ./Add-WAFIPException -Name "TestUser" -IPAddress $Config.ipAddress -PolicyName "testpolicy" -ResourceGroupName $Config.resourceGroupName } | Should throw
            Assert-MockCalled -CommandName 'Get-AzApplicationGatewayFirewallPolicy' -Times 1 -Scope It
        }
    }

    Context "Web Application Firewall policy does exist" {
        It 'The specified Resource was found in the resource group' {
            Mock Get-AzApplicationGatewayFirewallPolicy -MockWith {
                return @{
                    "PolicyName"        = $Config.resourceName
                    "ResourceGroupName" = $Config.resourceGroupName
                }
            { ./Add-WAFIPException @Params} | Should -Not throw
            Assert-MockCalled -CommandName 'Get-AzApplicationGatewayFirewallPolicy' -Times 1 -Scope It
            }
        }
    }

    Context "Check for users IP address" {
        $WafPolicy = @{
            CustomRules = @{
                MatchCondition = @{
                    MatchValues = @("192.168.0.10", "10.0.0.1")
                }
            }
        }
        It "does exist" {
            $IPAddress = "10.0.0.1"

            $IPExists = $WafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }

            $IPExists | Should -Be $true
        }
        It "does not exist" {
            $IPAddress = ""

            $IPExists = $WafPolicy.CustomRules | Where-Object { $_.MatchCondition.MatchValues -contains $IPAddress }

            $IPExists | Should -Not -Be $true
        }
    }

    Context "Check which priority custom rule should be set as" {
        It "sets the new priority as the starting priority" {
            $WafPolicy = @{
                CustomRules = @()
            }
            $StartPriority = 1
            if ($WafPolicy.CustomRules.Count -eq 0) {
                $NewPriority = $StartPriority
            }
            $NewPriority | Should -Be 1
        }
        It "sets the new priority as the next highest priority" {
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
            $NewPriority | Should -Be 3
        }
    }

    Context "New custom rule for the web application firewall policy created" {
        $NewCustomRule = @{
            Name = 'test'
            Priority = '3'
            RuleType = 'MatchRule'
            MatchCondition = 'MatchCondition'
            Action = 'Allow'
        }
        It 'should create a custom rule' {
            Mock New-AzApplicationGatewayFirewallCustomRule -MockWith {
                return @{
                    Name = 'test'
                    Priority = '3'
                    RuleType = 'MatchRule'
                    MatchCondition = 'MatchCondition'
                    Action = 'Allow'
                }
            { ./Add-WAFIPException @Params} | Should -Not throw
            Assert-MockCalled -CommandName 'New-AzApplicationGatewayFirewallCustomRule' -Times 1 -Scope It
            }
        }
        It 'should add a new custom rule' {
            $WafPolicy = @{
                CustomRules = @()
            }
            $IPExists = $true
            if ($IPExists) {
                $CustomRuleCreated = $WafPolicy.CustomRules += $NewCustomRule
            }
            $CustomRuleCreated | Should -Not -BeNullOrEmpty
        }
        It 'should not add a new custom rule' {
            $WafPolicy = @{
                CustomRules = @()
            }
            $IPExists = $true
            if (!$IPExists) {
                $CustomRuleCreated = $WafPolicy.CustomRules
            }
            $CustomRuleCreated | Should -BeNullOrEmpty
        }
    }
}
