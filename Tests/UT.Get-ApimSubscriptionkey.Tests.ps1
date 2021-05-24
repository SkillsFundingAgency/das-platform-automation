$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Get-ApimSubscriptionKey Unit Tests" -Tags @("Unit") {

    Context "Could not find subscription key due to bad paramater values" {

        It "The specified subscription key as not found, throw an error" {
            Mock Get-AzApiManagementSubscriptionKey -MockWith { return $null }
            { ./Get-ApimSubscriptionKey -ApimResourceGroup $Config.resourceGroupName -ApimName $Config.instanceName -SubscriptionId $Config.resourceName -PipelineVariableName $Config.pipelineVariableName } | Should throw
            Assert-MockCalled -CommandName 'Get-AzApiManagementSubscriptionKey' -Times 1 -Scope It
        }

    }

    Context "Subscription key found" {

        It "Subscription key found" {
            Mock Get-AzApiManagementSubscriptionKey -MockWith { return @{ "Primarykey" = "key" } }
            { ./Get-ApimSubscriptionKey -ApimResourceGroup $Config.resourceGroupName -ApimName $Config.instanceName -SubscriptionId $Config.resourceName -PipelineVariableName $Config.pipelineVariableName } | Should not throw
            Assert-MockCalled -CommandName 'Get-AzApiManagementSubscriptionKey' -Times 1 -Scope It
        }

    }

}
