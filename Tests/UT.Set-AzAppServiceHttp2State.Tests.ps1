Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Set-AzAppServiceHttp2State Unit Tests" -Tags @("Unit") {
    $Params = @{
        AppServiceName = "das-at-fooapi-as"
        AppServiceResourceGroup = "das-at-foo-rg"
    }

    Context "The WhatIf parameter is passed in" {
        It "Should not call Set-AzResource" {
            Mock Get-AzWebApp
            Mock Get-AzResource
            Mock Set-AzResource
            $Params["WhatIf"] = $true

            .\Set-AzAppServiceHttp2State.ps1 @Params

            Assert-MockCalled -CommandName Get-AzWebApp -Times 0 -Scope It
            Assert-MockCalled -CommandName Get-AzResource -Times 1 -Scope It
            Assert-MockCalled -CommandName Set-AzResource -Times 0 -Scope It
        }
    }

}
