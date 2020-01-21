$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Code-Analysis-Scripts\

Describe "Import-OwaspDependencyCheckResults Unit Tests" -Tags @("Unit") {
    It "Should return 200 if successful" {
        $TestParams = @{
            CustomerId = $Config.customerId
            SharedKey  = $Config.sharedKey
        }
        $ENV:BUILD_REPOSITORY_NAME = $Config.repositoryName
        $ENV:BUILD_SOURCEBRANCHNAME = $Config.branchName
        $ENV:BUILD_BUILDNUMBER = $Config.buildNumber
        $ENV:BUILD_SOURCEVERSION = $Config.sourceVersion
        Mock Invoke-WebRequest {
            [pscustomobject]@{ StatusCode = 200 }
        }
        Mock Import-Csv {
            [pscustomobject]@{ Project = 'OWASP Dependency Check' }
        }
        $result = ./Import-OwaspDependencyCheckResults.ps1 @TestParams
        $result | Should be 200
    }
}
