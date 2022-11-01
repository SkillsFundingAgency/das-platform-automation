$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-AppServiceIpException Unit Tests" -Tags @("Unit") {

    $env:Release_RequestedFor = $Config.ruleName

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.whitelistResourceName -RuleName $Config.ruleName } | Should throw "Could not find a resource matching AResource in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resource exists but failed to get access restriction config" {
        It "The specified Resource Config was not found, throw an error" {
            Mock Get-AzResource -MockWith { return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.whitelistResourceName[0]
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { throw "Operation returned an invalid status code 'NotFound'" }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.whitelistResourceName[0] -RuleName $Config.ruleName } | Should throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
        }
    }

    Context "Resource exists and adds access restriction config" {
        It "The specified Resource Config was updated, should not throw an error" {
            Mock Get-AzResource -MockWith { return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.whitelistResourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { return @{
                "MainSiteAccessRestrictions" = @("foo","bar")
                }
            }
            Mock Add-AzWebAppAccessRestrictionRule -MockWith { return $null }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.whitelistResourceName -RuleName $Config.ruleName } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Add-AzWebAppAccessRestrictionRule' -Times 1 -Scope It
        }
    }

    Context "Resource exists but does not have access restrictions" {
        It "The specified Resource Config was identified to not have network restrictions, no whitelist required." {
            Mock Get-AzResource -MockWith { return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.whitelistResourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { return @{
                "MainSiteAccessRestrictions" = @("allow")
                }
            }
            Mock Add-AzWebAppAccessRestrictionRule -MockWith { return $null }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.whitelistResourceName -RuleName $Config.ruleName } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Add-AzWebAppAccessRestrictionRule' -Times 0 -Scope It
        }
    }

    Context "Resource exists and has a deny all rule present in it's access restrictions" {
        It "The specified Resource Config was identified to have a deny all network restriction, whitelist will be added at a lesser priority to the DenyAll rule" {
            Mock Get-AzResource -MockWith { return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.whitelistResourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { return @{
                "MainSiteAccessRestrictions" = @("Deny")
                }
            }
            Mock Add-AzWebAppAccessRestrictionRule -MockWith { return $null }
            { ./Add-AppServiceIpException -IpAddress $Config.ipAddress -ResourceName $Config.whitelistResourceName -RuleName $Config.ruleName } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Add-AzWebAppAccessRestrictionRule' -Times 0 -Scope It
        }
    }
}
