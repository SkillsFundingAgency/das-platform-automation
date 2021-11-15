$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-CosmosDbIpException Unit Tests" -Tags @("Unit") {

    $Params = @{
        IpAddress           = $Config.ipAddress
        ResourceNamePattern = $Config.ResourceName
    }

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-CosmosDbIpException @Params } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
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
            { ./Add-CosmosDbIpException @Params } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resource exists, there are restrictions for this cosmos db so adding rule" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith {
                return @{
                    "Name"              = $Config.resourceName
                    "ResourceGroupName" = $Config.resourceGroupName
                }
            }
            Mock Get-AzCosmosDBAccount -MockWith {
                return @{
                    "Name"    = $Config.resourceName
                    "IpRules" = @{
                        "IpAddressOrRangeProperty" = ""
                    }
                }
            }
            Mock Update-AzCosmosDBAccount -MockWith { return $null }
            { ./Add-CosmosDbIpException @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzCosmosDBAccount' -Times 1 -Scope It
        }
    }
}
