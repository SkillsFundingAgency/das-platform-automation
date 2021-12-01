$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-AzSqlIpException Unit Tests" -Tags @("Unit") {

    $env:RELEASE_REQUESTEDFOR = $Config.ruleName
    $Params = @{
        IpAddress           = $Config.ipAddress
        ResourceNamePattern = $Config.resourceName
        Name                = "TestUser"
    }

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-AzSqlIpException @Params } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resources exists and firewall exception with given name already exists" {
        It "Should update the firewall exceptions to the found resources" {

            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.serverName
                }
            }
            Mock Get-AzSqlServerFirewallRule -MockWith {
                return @{
                    "FirewallRuleName" = "TestUser"
                }
            }
            Mock Set-AzSqlServerFirewallRule -MockWith { return $null }
            { ./Add-AzSqlIpException @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzSqlServerFirewallRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzSqlServerFirewallRule' -Times 1 -Scope It
        }
    }

    Context "Resources exists and firewall exception with given doesn't exist" {
        It "Should add the firewall exceptions to the found resources" {

            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.serverName
                }
            }
            Mock Get-AzSqlServerFirewallRule -MockWith { return @() }
            Mock New-AzSqlServerFirewallRule -MockWith { return $null }
            { ./Add-AzSqlIpException @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzSqlServerFirewallRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzSqlServerFirewallRule' -Times 1 -Scope It
        }
    }

}
