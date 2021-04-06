$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Invoke-CdnContentPurge Unit Tests" -Tags @("Unit") {

    Context "Purge Content Parameter Blank" {
        It "Should throw an exception to warn that no content purge will be run" {
            { ./Invoke-CdnContentPurge -CDNProfileResourceGroup $Config.resourceGroupName -CDNProfileName $Config.CdnProfileName -CDNEndPointName $Config.CDNEndPointName -PurgeContent $Config.blankPurge } | Should throw "Purge Content blank will not run purge"
        }
    }

    Context "Resource Group or CDN Profile does not exist" {
        It "The specified Resource Group or CDN Profile was not found in the subscription, throw an error" {
            Mock Get-AzCdnEndpoint -MockWith { Return $null }
            { ./Invoke-CdnContentPurge -CDNProfileResourceGroup $Config.resourceGroupName -CDNProfileName $Config.CdnProfileName -CDNEndPointName $Config.CDNEndPointName -PurgeContent $Config.purgeContent } | Should throw "CDN Endpoint does not exist"
            Assert-MockCalled -CommandName 'Get-AzCdnEndpoint'  -Times 1 -Scope It
        }
    }

    Context "Parameters are ok" {
        It "Should call Unpublish-AzCdnEndpointContent" {
            Mock Get-AzCdnEndpoint -MockWith {
                $cdnEndpointExists = [Microsoft.Azure.Commands.Cdn.Models.Endpoint.PSEndpoint]::new()
                return $cdnEndpointExists
            }
            Mock Unpublish-AzCdnEndpointContent -MockWith { Return $null }
            { ./Invoke-CdnContentPurge -CDNProfileResourceGroup $Config.resourceGroupName -CDNProfileName $Config.CdnProfileName -CDNEndPointName $Config.CDNEndPointName -PurgeContent $Config.purgeContent } | Should Not Throw
            Assert-MockCalled -CommandName 'Get-AzCdnEndpoint' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Unpublish-AzCdnEndpointContent' -Times 1 -Scope It
        }
    }
}
