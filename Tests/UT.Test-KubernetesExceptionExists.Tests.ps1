$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Test-KubernetesExceptionExists Unit Tests" -Tags @("Unit") {

    Context "Test whether exception CRD exists" {
        It "Should return an exception found message when the exception is found in the KubectlOutput" {
            ./Test-KubernetesExceptionExists -KubectlOutput $Config.KubernetesExceptionReduced -ExceptionName $Config.KubernetesExceptionName | Should Contain "Exception $($Config.KubernetesExceptionName) found."
        }

        It "Should return an exception not found message when the exception is not found in the KubectlOutput" {
            ./Test-KubernetesExceptionExists -KubectlOutput $Config.KubernetesExceptionReduced -ExceptionName 'NoneExistentException' | Should Contain "Exception NoneExistentException not found."
        }
    }
}
