$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Scripts\Infrastructure\

Describe "Add-CosmosDbIpException Unit Tests" -Tags @("Unit") {

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-CosmosDbIpException -IpAddress $Config.ipAddress -ResourceNamePattern $Config.resourceName } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resource exists but there are no restrictions for this Cosmos db" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceId" = $Config.resourceId
                }
            }
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-CosmosDbIpException -IpAddress $Config.ipAddress -ResourceNamePattern $Config.resourceName } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resource exists, there are restrictions for this cosmos db so adding rule" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceId" = $Config.resourceId
                    "Properties" = @{
                        "ipRangeFilter" = ""
                    }
                }
            }
            Mock Set-AzResource -MockWith { return $null }
            { ./Add-CosmosDbIpException -IpAddress $Config.ipAddress -ResourceNamePattern $Config.resourceName } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 2 -Scope It
        }
    }
}
