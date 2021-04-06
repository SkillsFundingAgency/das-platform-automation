$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-AppServiceIpException Unit Tests" -Tags @("Unit") {

    $env:Release_RequestedFor = $Config.ruleName

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.resourceName } | Should throw "Could not find a resource matching $($config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resource exists but failed to get access restriction config" {
        It "The specified Resource Config was not found, throw an error" {
            Mock Get-AzResource -MockWith { return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.resourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { throw "Operation returned an invalid status code 'NotFound'" }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.resourceName } | Should throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
        }
    }

    Context "Resource exists and adds access restriction config" {
        It "The specified Resource Config was updated, should not throw an error" {
            Mock Get-AzResource -MockWith { return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.resourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { return $null }
            Mock Add-AzWebAppAccessRestrictionRule -MockWith { return $null }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.resourceName } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Add-AzWebAppAccessRestrictionRule' -Times 1 -Scope It
        }
    }
}
