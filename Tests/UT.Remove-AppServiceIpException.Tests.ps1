$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AppServiceIpException Unit Tests" -Tags @("Unit") {

    $Params = @{
        IpAddress           = $Config.ipAddress
        ResourceName        = $Config.resourceName
    }

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Remove-AppServiceIpException @Params } | Should throw "Could not find a resource matching $($Config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resources exists and app service ip exception doesn't exist" {
        It "Should output existing access restriction with given IP does not exist" {

            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Name"              = $Config.resourceName
                }
            }
            Mock Get-AzWebAppAccessRestrictionConfig -MockWith { return $null }
            Mock Write-Output -MockWith {}
            { ./Remove-AppServiceIpException @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Times 1 -Scope It -ParameterFilter { $InputObject -eq " -> Could not find whitelisted $($Config.ipAddress) to remove!" }
        }
    }

    Context "Resources exists and app service ip exception exists" {
        It "Should remove the ip access restriction to the found resources" {

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
            { ./Remove-AppServiceIpException @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzWebAppAccessRestrictionConfig' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzWebAppAccessRestrictionRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Times 2 -Scope It
            Assert-MockCalled -CommandName 'Write-Output' -Times 1 -Scope It -ParameterFilter { $InputObject -eq "  -> Removing $($Config.ipAddress)" }
            Assert-MockCalled -CommandName 'Write-Output' -Times 1 -Scope It -ParameterFilter { $InputObject -eq "  -> $($Config.ipAddress), removed!" }
        }
    }

}