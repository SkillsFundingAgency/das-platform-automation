$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "New-ServiceBusConnectionStrings Unit Tests" -Tags @("Unit") {

    Context "Service Bus Namespace does not exist" {
        It "The specified Service Bus Namespace  was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { Return $null }
            { ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights } | Should throw "Could not find servicebus namespace $($Config.NamespaceName)"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }
    }
    Context "Namespace and Authorisation rules exists, Return Authorisation rules Connection Strings" {


        Mock Get-AzResource -MockWith {
            return @{
                "Name" = $Config.NamespaceName
                "ResourceGroupName"= $Config.ResourceGroupName
                "ResourceType" = " Microsoft.ServiceBus/namespaces"
                "Location" = "westeurope"
                "ResourceId" = "aRsourceID"
            }
        }

        Mock Get-AzServiceBusAuthorizationRule -MockWith {
            return @{
                "Id" = "anId"
                "Name" = $Config.AuthorizationRuleName
                "Rights" = $Config.Rights
            }

        }

        Mock Get-AzServiceBusKey -MockWith {
            $ServiceBusKey =[Microsoft.Azure.Commands.ServiceBus.Models.PSListKeysAttributes]::new($null)
            return $ServiceBusKey

        }

        It "Primary Storage Account Key is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

        It "Secondary Storage Account Key is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights -ConnectionStringType "Secondary"
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

    }

    Context "Namespace exists but Authorisation rules do not exists,Create new Rule and Return Authorisation rules Connection Strings" {



        Mock Get-AzResource -MockWith {
            return @{
                "Name" = $Config.NamespaceName
                "ResourceGroupName"= $Config.ResourceGroupName
                "ResourceType" = " Microsoft.ServiceBus/namespaces"
                "Location" = "westeurope"
                "ResourceId" = "aRsourceID"
            }
        }

        Mock Get-AzServiceBusAuthorizationRule -MockWith {
            return $null

        }

        Mock Get-AzServiceBusKey -MockWith {
            $ServiceBusKey =[Microsoft.Azure.Commands.ServiceBus.Models.PSListKeysAttributes]::new($null)
            return $ServiceBusKey

        }

        Mock New-AzServiceBusAuthorizationRule -MockWith {
            return $null
        }

        It "Primary Storage Account Key is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzServiceBusAuthorizationRule' -Times 1
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

        It "Secondary Storage Account Key is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights -ConnectionStringType "Secondary"
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzServiceBusAuthorizationRule' -Times 1
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

    }
}
