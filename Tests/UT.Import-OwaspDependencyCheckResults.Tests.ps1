$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Code-Analysis-Scripts\

Describe "Import-OwaspDependencyCheckResults Unit Tests" -Tags @("Unit") {

    It "Should fail with invalid CustomerId" {
        $TestParams = @{
            CustomerId = $Config.customerId
            SharedKey  = $Config.validBase64String
        }
        $ENV:BUILD_REPOSITORY_NAME = $Config.repositoryName
        $ENV:BUILD_SOURCEBRANCHNAME = $Config.branchName
        $ENV:BUILD_BUILDNUMBER = $Config.buildNumber
        $ENV:BUILD_SOURCEVERSION = $Config.sourceVersion
        Mock Import-Csv {
            [pscustomobject]@{ Project = 'OWASP Dependency Check' }
        }
        { ./Import-OwaspDependencyCheckResults @TestParams } | Should throw "No such host is known"
    }

    It "Should fail with invalid Base-64 string for SharedKey" {
        $TestParams = @{
            CustomerId = $Config.customerId
            SharedKey  = $Config.invalidBase64String
        }
        $ENV:BUILD_REPOSITORY_NAME = $Config.repositoryName
        $ENV:BUILD_SOURCEBRANCHNAME = $Config.branchName
        $ENV:BUILD_BUILDNUMBER = $Config.buildNumber
        $ENV:BUILD_SOURCEVERSION = $Config.sourceVersion
        Mock Import-Csv {
            [pscustomobject]@{ Project = 'OWASP Dependency Check' }
        }
        $ErrorMessage = 'Exception calling "FromBase64String" with "1" argument(s): "The input is not a valid Base-64 string as it contains a non-base 64 character, more than two padding characters, or an illegal character among the padding characters."'
        { ./Import-OwaspDependencyCheckResults @TestParams } | Should throw $ErrorMessage
    }
}
