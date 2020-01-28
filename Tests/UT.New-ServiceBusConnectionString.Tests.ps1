$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Scripts\Infrastructure\

Describe "New-ServiceBusConnectionString Unit Tests" -Tags @("Unit") {

    Context "Service Bus namespace does not exist" {

        It "The specified Service Bus namespace was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { Return $null }
            { ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights } | Should throw "Could not find Service Bus namespace $($Config.NamespaceName)"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }

    }

    Context "Service Bus namespace and authorization rule exist, return authorisation rule Connection Strings" {

        Mock Get-AzResource -MockWith {
            return @{
                "Name" = $Config.NamespaceName
                "ResourceGroupName"= $Config.ResourceGroupName
                "ResourceType" = "Microsoft.ServiceBus/namespaces"
                "Location" = $Config.Location
                "ResourceId" = "aResourceId"
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

        It "Primary Connection String is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

        It "Secondary Connection String is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights -ConnectionStringType "Secondary"
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

    }

    Context "Service Bus namespace exists but the authorization rule does not, create new authorization rule and return the Connection Strings" {

        Mock Get-AzResource -MockWith {
            return @{
                "Name" = $Config.NamespaceName
                "ResourceGroupName"= $Config.ResourceGroupName
                "ResourceType" = " Microsoft.ServiceBus/namespaces"
                "Location" = $Config.Location
                "ResourceId" = "aResourceID"
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

        It "Primary Connection String is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzServiceBusAuthorizationRule' -Times 1
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

        It "Secondary Connection String is returned and environment output provided" {
            $ConnectionString = ./New-ServiceBusConnectionString -NamespaceName $Config.NamespaceName -AuthorizationRuleName $Config.AuthorizationRuleName -Rights $Config.Rights -ConnectionStringType "Secondary"
            $ConnectionString | Should BeLike '*task.setvariable*'
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusAuthorizationRule' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzServiceBusAuthorizationRule' -Times 1
            Assert-MockCalled -CommandName 'Get-AzServiceBusKey' -Times 1 -Scope It
        }

    }

}
