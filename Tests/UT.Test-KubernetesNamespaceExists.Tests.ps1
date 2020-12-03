$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Test-KubernetesNamespaceExists Unit Tests" -Tags @("Unit") {

    Context "Test whether namespace CRD exists" {
        It "Should return a namespace found message when the namespace is found in the KubectlOutput" {
         ./Test-KubernetesNamespaceExists -KubectlOutput $Config.KubernetesNamespaceReduced -Namespace $Config.KubernetesNamespace | Should Contain "Namespace $($Config.KubernetesNamespace) found."
        }

        It "Should return a namespace not found message when the namespace is not found in the KubectlOutput" {
            ./Test-KubernetesNamespaceExists -KubectlOutput $Config.KubernetesNamespaceReduced -Namespace 'NoneExistentNamespace' | Should Contain "Namespace NoneExistentNamespace not found."
        }
    }
}
