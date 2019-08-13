$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Set-StatuscakeTest Unit Tests" -Tags @("Unit") {
    Mock Invoke-RestMethod -MockWith {
        if ($Headers["Username"] -ne "StatuscakeUsername" -and $Headers["API"] -ne "my-api-key123") {
            throw "Invalid auth"
        }

        switch ($Method) {
            "GET" {
                return @(@{
                        TestID      = 123
                        WebsiteName = $Config.statuscakeTestName
                        WebsiteURL  = $Config.statuscakeTestUrl
                    })
            }
            "PUT" {
                if ($Body.Split("&") -contains "TestID=123") {
                    return @{
                        Message = "Test has been updated!"
                    }
                }
                else {
                    return @{
                        Message = "Test Inserted"
                    }
                }
            }
        }
    }

    Context "No existing Statuscake test" {
        It "Should create a new test when parameters are valid" {
            $TestParams = @{
                StatuscakeUsername = "StatuscakeUsername"
                StatuscakeAPIKey   = "my-api-key123"
                TestName           = "NewTest"
                TestUrl            = "https://www.newtest.com"
            }
            $Output = ./Set-StatuscakeTest.ps1 @TestParams
            $Output | Should Be "Test Inserted"
        }
    }

    Context "Statuscake tests exist" {
        It "Should update an existing statuscake test" {
            $TestParams = @{
                StatuscakeUsername = "StatuscakeUsername"
                StatuscakeAPIKey   = "my-api-key123"
                TestName           = $Config.statuscakeTestName
                TestUrl            = $Config.statuscakeTestUrl
            }
            $Output = ./Set-StatuscakeTest.ps1 @TestParams
            $Output | Should Be "Test has been updated!"
        }
    }

    Context "Invalid inputs" {
        It "Should throw if the test URL is invalid" {
            $TestParams = @{
                StatuscakeUsername = "StatuscakeUsername"
                StatuscakeAPIKey   = "my-api-key123"
                TestName           = "InvalidTest"
                TestUrl            = "ThisIsNotAURL"
            }
            { ./Set-StatuscakeTest.ps1 @TestParams } | Should throw
        }

        It "Should throw if invalid auth headers are passed" {
            $TestParams = @{
                StatuscakeUsername = "InvalidUsername"
                StatuscakeAPIKey   = "InvalidPassword"
                TestName           = $Config.statuscakeTestName
                TestUrl            = $Config.statuscakeTestUrl
            }
            { ./Set-StatuscakeTest.ps1 @TestParams } | Should throw "Invalid auth"
        }
    }
}
