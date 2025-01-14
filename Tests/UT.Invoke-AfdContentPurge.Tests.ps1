$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Invoke-AfdContentPurge Unit Tests" -Tags @("Unit") {

    Context "Purge Content Parameter Blank" {
        It "Should throw an exception to warn that no content purge will be run" {
            { ./Invoke-AfdContentPurge -AFDProfileResourceGroup $Config.resourceGroupName -AFDProfileName $Config.CdnProfileName -AFDEndPointName $Config.CDNEndPointName -PurgeContent $Config.blankPurge } | Should throw "Purge Content blank will not run purge"
        }
    }

    Context "Resource Group or CDN Profile does not exist" {
        It "Should throw an expection to warn that the the specified Resource Group or CDN Profile was not found in the subscription" {
            Mock Get-AzFrontDoorCdnEndpoint -MockWith { Return $null }
            { ./Invoke-AfdContentPurge -AFDProfileResourceGroup $Config.resourceGroupName -AFDProfileName $Config.CdnProfileName -AFDEndPointName $Config.CDNEndPointName -PurgeContent $Config.purgeContent } | Should throw "AFD Endpoint does not exist"
            Assert-MockCalled -CommandName 'Get-AzFrontDoorCdnEndpoint'  -Times 1 -Scope It
        }
    }

    Context "Parameters are ok" {
        It "Should call Clear-AzFrontDoorCdnEndpointContent" {
            Mock Get-AzFrontDoorCdnEndpoint -MockWith {
                $cdnEndpointExists = [Microsoft.Azure.PowerShell.Cmdlets.Cdn.Models.Api20240201.Endpoint]::new()
                return $cdnEndpointExists
            }
            Mock Clear-AzFrontDoorCdnEndpointContent -MockWith { Return $null }
            { ./Invoke-AfdContentPurge -AFDProfileResourceGroup $Config.resourceGroupName -AFDProfileName $Config.CdnProfileName -AFDEndPointName $Config.CDNEndPointName -PurgeContent $Config.purgeContent } | Should Not Throw
            Assert-MockCalled -CommandName 'Get-AzFrontDoorCdnEndpoint' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Clear-AzFrontDoorCdnEndpointContent' -Times 1 -Scope It
        }
    }
}
