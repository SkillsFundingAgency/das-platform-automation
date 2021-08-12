$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts

Describe "Set-BackEndAccessRestrictions Unit Tests" -Tags @("Unit") {
    Context "Virtual Network parameters are invalid" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzVirtualNetwork -MockWith { return @($null) }
            { .\Set-BackEndAccessRestrictionsVariable.ps1 -SharedEnvResourceGroup $Config.resourceGroupName -SharedEnvVirtualNetworkName $Config.virtualNetworkName -BackEndAccessRestrictionsExcludedSubnets $Config.virtualNetworkSubnets -ResourceEnvironmentName $Config.resourceEnvironmentName -UnrestrictedEnvironments $Config.unrestrictedEnvironments -UptimeMonitoringAccessRestrictions $Config.nameIpAddressObject } | Should throw "Could not find a virtual network matching $($Config.virtualNetworkName) and $($Config.resourceGroupName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzVirtualNetwork' -Times 1 -Scope It
        }
    }
    Context "UptimeMonitoringAccessRestrictions parameter is invalid" {
        It "The UptimeMonitoringAccessRestrictions parameter is not valid JSON, throw an error" {
            Mock Get-AzVirtualNetwork -MockWith {
                return @{
                    Subnets = @(
                        @{
                            "Name"= "foo-sn"
                        }
                    )
                }
            }
            Mock Get-AzSubscription -MockWith {
                return @{
                    Id = $Config.guid
                }
            }
            { .\Set-BackEndAccessRestrictionsVariable.ps1 -SharedEnvResourceGroup $Config.resourceGroupName -SharedEnvVirtualNetworkName $Config.virtualNetworkName -BackEndAccessRestrictionsExcludedSubnets $Config.virtualNetworkSubnets -ResourceEnvironmentName $Config.resourceEnvironmentName -UnrestrictedEnvironments $Config.unrestrictedEnvironments -UptimeMonitoringAccessRestrictions $Config.invalidJson } | Should throw "Could not convert invalid JSON of UptimeMonitoringAccessRestrictions parameter"
            Assert-MockCalled -CommandName 'Get-AzVirtualNetwork' -Times 1 -Scope It
        }
    }
    Context "Output a BackEndAccessRestrictions variable from valid parameters" {
        It "Output a BackEndAccessRestrictions variable from valid parameters" {
            Mock Get-AzVirtualNetwork -MockWith {
                return @{
                    Subnets = @(
                        @{
                            "Name"= "foo-sn"
                        }
                    )
                }
            }
            { .\Set-BackEndAccessRestrictionsVariable.ps1 -SharedEnvResourceGroup $Config.resourceGroupName -SharedEnvVirtualNetworkName $Config.virtualNetworkName -BackEndAccessRestrictionsExcludedSubnets $Config.virtualNetworkSubnets -ResourceEnvironmentName $Config.resourceEnvironmentName -UnrestrictedEnvironments $Config.unrestrictedEnvironments -UptimeMonitoringAccessRestrictions $Config.nameIpAddressObject } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzVirtualNetwork' -Times 1 -Scope It
        }
    }
}
