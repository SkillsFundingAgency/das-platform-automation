$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AppServiceIpException Unit Tests" -Tags @("Unit") {

    $ParamsSingleAppService = @{
        IpAddress           = $Config.ipAddress
        ResourceName        = $Config.whitelistResourceNameSingle
    }
    $ParamsMultipleAppServices = @{
        IpAddress           = $Config.ipAddress
        ResourceName        = $Config.whitelistResourceName
    }

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Remove-AppServiceIpException @ParamsMultipleAppServices } | Should throw "Could not find a resource matching $($Config.whitelistResourceName[0]) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Exactly 1 -Scope It
        }
    }

    Context "Resources exist and app services ip exception doesn't exist" {
        It "Should output existing access restriction with given IP does not exist" {

            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.whitelistResourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { return $null }
            Mock Write-Output -MockWith {}
            { ./Remove-AppServiceIpException @ParamsMultipleAppServices } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Exactly 2 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Exactly 2 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq " -> Could not find whitelisted $($Config.ipAddress) to remove on $($Config.whitelistResourceName[0])!" }
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq " -> Could not find whitelisted $($Config.ipAddress) to remove on $($Config.whitelistResourceName[1])!" }
        }
    }

    Context "Resources exist and app services ip access restriction rules exist" {
        It "Should remove the ip access restriction to the found resources" {

            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.whitelistResourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith {
                return @{
                    "MainSiteAccessRestrictions" = @{
                        "IpAddress" = "$($Config.ipAddress)/32"
                    }
                }
            }
            Mock Remove-AzWebAppAccessRestrictionRule -MockWith { return $null }
            Mock Write-Output -MockWith {}
            { ./Remove-AppServiceIpException @ParamsMultipleAppServices } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Exactly 2 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Exactly 2 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzWebAppAccessRestrictionRule' -Exactly 2 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 4 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "  -> Removing $($Config.ipAddress) from $($Config.whitelistResourceName[0])" }
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "  -> $($Config.ipAddress), removed from $($Config.whitelistResourceName[0])!" }
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "  -> Removing $($Config.ipAddress) from $($Config.whitelistResourceName[1])" }
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "  -> $($Config.ipAddress), removed from $($Config.whitelistResourceName[1])!" }
        }
    }

    Context "Singular resource exists and app service ip access restriction rule exists" {
        It "Should remove the ip access restriction to the found resource" {

            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.resourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith {
                return @{
                    "MainSiteAccessRestrictions" = @{
                        "IpAddress" = "$($Config.ipAddress)/32"
                    }
                }
            }
            Mock Remove-AzWebAppAccessRestrictionRule -MockWith { return $null }
            Mock Write-Output -MockWith {}
            { ./Remove-AppServiceIpException @ParamsSingleAppService } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Exactly 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Exactly 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzWebAppAccessRestrictionRule' -Exactly 1 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 2 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "  -> Removing $($Config.ipAddress) from $($Config.whitelistResourceName[0])" }
            Assert-MockCalled -CommandName 'Write-Output' -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "  -> $($Config.ipAddress), removed from $($Config.whitelistResourceName[0])!" }
        }
    }

}