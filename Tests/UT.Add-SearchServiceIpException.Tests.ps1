$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Add-SearchServiceIpException Unit Tests" -Tags @("Unit") {

    $Params = @{
        IpAddress           = $Config.ipAddress
        ResourceNamePattern = $Config.resourceName
    }

    Context "Resource does not exist" {
        It "The specified Resource was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { return $null }
            { ./Add-SearchServiceIpException @Params } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }

    Context "Resource does exist" {
        It "The specified Resource was  found in the subscription" {
            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceId" = $Config.resourceId
                }
            }
            { ./Add-SearchServiceIpException @Params } | Should not throw
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }
}
