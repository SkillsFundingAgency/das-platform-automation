$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Get-ProductApplicationInsights Unit Tests" -Tags @("Unit") {

    Context "Could not find application insights due to bad paramater values" {

        It "The specified application insights was not found, throw an error" {
            Mock Get-AzApplicationInsights -MockWith { return $null }
            { ./Get-ProductApplicationInsights -AppInsightsResourceGroup $Config.resourceGroupName -AppInsightsName $Config.instanceName } | Should throw
            Assert-MockCalled -CommandName 'Get-AzApplicationInsights' -Times 1 -Scope It
        }

    }

    Context "Application insights found" {

        It "Application insights found" {
            Mock Get-AzApplicationInsights -MockWith { return @{ "ApplicationInsightsName" = "ApplicationInsightsName" } }
            { ./Get-ProductApplicationInsights -AppInsightsResourceGroup $Config.resourceGroupName -AppInsightsName $Config.instanceName } | Should not throw
            Assert-MockCalled -CommandName 'Get-AzApplicationInsights' -Times 1 -Scope It
        }

    }

}
