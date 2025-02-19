Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Retain Build Unit Tests" -Tags @("Unit") {

    $Params = @{
        DefinitionId  = "3223"
        RunId        = "896262"
        OwnerId      = "User:ea697f47-8ede-489e-a18c-afb8f4ba1495"
        CollectionUri = "https://dev.azure.com/sfa-gov-uk/"
        TeamProject  = "Digital Apprenticeship Service"
        AccessToken  = "FakeAccessToken123"
    }

    Context "Successful API Request" {
        Mock Invoke-RestMethod -MockWith { return @{ id = 12345; message = "Lease created" } }
        It "Should retain the build successfully" {
            { ./Retain-Build.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It
        }
    }

    Context "Missing Required Parameters" {
        $InvalidParams = $Params.Clone()
        $InvalidParams.Remove("RunId")

        It "Should throw an error when RunId is missing" {
            { ./Retain-Build.ps1 @InvalidParams } | Should throw
        }
    }

    Context "API Request Fails" {
        Mock Invoke-RestMethod -MockWith { throw "API request failed" }
        It "Should handle API failures gracefully" {
            { ./Retain-Build.ps1 @Params } | Should throw "API request failed"
            Assert-MockCalled -CommandName Invoke-RestMethod -Exactly 1 -Scope It
        }
    }

    Context "Missing Access Token" {
        $InvalidParams = $Params.Clone()
        $InvalidParams["AccessToken"] = ""

        It "Should fail if AccessToken is missing" {
            { ./Retain-Build.ps1 @InvalidParams } | Should throw "ERROR: AccessToken is missing!"
        }
    }
}
