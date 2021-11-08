$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts

Describe "Publish-AzureCloudServiceDeployment Unit Tests" -Tags @("Unit") {
    Context "Cloud service does not exist, should not throw an error" {
        It "Cloud service does not exist, should not throw an error" {
            Function Get-AzureSubscription { }
            Function Set-AzureSubscription { }
            Function Get-AzureService { }
            Function New-AzureService { }
            Mock Get-AzureSubscription -MockWith {
                return @{
                    SubscriptionId = $Config.guid
                }
            }
            Mock Set-AzureSubscription -MockWith { return $null }
            Mock Get-AzureService -MockWith { return $null }
            Mock New-AzureService -MockWith { return $null }
            { .\Publish-AzureCloudServiceDeployment.ps1 -ServiceName das-at-foobar-cs -ServiceLocation foobar -ClassicStorageAccountName dasatfoobarstr -ServicePackageFile ./SFA.DAS.FooBar.CloudService.cspkg -ServiceConfigFile ./ServiceConfiguration.Cloud.cscfg -Slot Production } | Should not throw
            Assert-MockCalled -CommandName 'Get-AzureSubscription' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzureSubscription' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzureService' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzureService' -Times 1 -Scope It
        }
    }
}
