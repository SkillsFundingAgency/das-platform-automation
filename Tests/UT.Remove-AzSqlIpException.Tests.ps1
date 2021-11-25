Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AzSqlIpException Unit Tests" -Tags @("Unit") {
    $Params = @{
        IPAddress           = "1.2.3.4"
        ResourceNamePattern = "das-myserver"
        Name                = "rule1"
    }

    Context "Resource exists and firewall rule with given name exists " {
        It "Should remove the firewall rule from the found resources" {
            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = "das-test-pester-rg"
                    "Name"              = "das-pester-shared-sql"
                }
            }
            Mock Get-AzSqlServerFirewallRule -MockWith {
                return @{
                    "FirewallRuleName" = "rule1"
                    "StartIPAddress"   = "1.2.3.4"
                }
            }
            Mock Remove-AzSqlServerFirewallRule -MockWith { return $null }
            { ./Remove-AzSqlIpException @Params } | Should not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzSqlServerFirewallRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzSqlServerFirewallRule' -Times 1 -Scope It
        }

    }

    Context "Resource doesn't exists and firewall rule doesn't exist" {
        It "Should throw an error, Unable to find the firewallrulename" {
            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = "das-test-pester-rg"
                    "Name"              = "das-pester-shared-sql"
                }
            }

            Mock Get-AzSqlServerFirewallRule -MockWith {
                return @{
                    "FirewallRuleName" = "rule1"
                    "StartIPAddress"   = "1.2.3.4"
                }
            }
            Mock Get-AzResource -MockWith {return $null}
            Mock Get-AzSqlServerFirewallRule -MockWith {return $null}
            {./Remove-AzSqlIpException @Params} | should throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzSqlServerFirewallRule' -Times 0 -Scope It
        }

    }
}
