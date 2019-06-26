$Config = Get-Content $PSScriptRoot\..\tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\infrastructure-scripts\

Describe "Get-AzStorageAccountConnectionString Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "The specified Resource Group was not found in the subscription, throw an error" {
            Mock Get-AzResourceGroup -MockWith { Return $null }
            { ./Get-AzStorageAccountConnectionString -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -OutputVariable $Config.outputVariable } | Should throw "Resource Group $($Config.resourceGroupName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
        }
    }

    Context "Resource Group exists but not Storage Account" {
        It "The specified Storage Account was not found in the subscription, throw an error" {
            Mock Get-AzResourceGroup -MockWith {
                $ResourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new($Config.location, $null, $Config.resourceGroupName)
                return $ResourceGroupExist
            }
            Mock Get-AzStorageAccount -MockWith { Return $null }
            { ./Get-AzStorageAccountConnectionString -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -OutputVariable $Config.outputVariable } | Should throw "Storage Account $($Config.storageAccountName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
        }
    }

    Context "Resource Group and Storage Account Exists, Return Storage Account Connection Strings" {

        Mock Get-AzResourceGroup -MockWith {
            $ResourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new("West Europe", $null, $Config.resourceGroupName)
            return $ResourceGroupExist
        }

        Mock Get-AzStorageAccount -MockWith {
            $StorageAccountExist = [Microsoft.Azure.Management.Storage.Models.StorageAccount]::new("West Europe", $null, $Config.storageAccountName)
            return $StorageAccountExist
        }

        Mock Get-AzStorageAccountKey -MockWith {
            $KeyArr = @()
            1..2 | ForEach-Object {
                $KeyArr += [Microsoft.Azure.Management.Storage.Models.StorageAccountKey]::new("Key$_", "Key$_", 1)
            }
            return $KeyArr
        }

        It "Primary Storage Account Key is returned and environment output provided" {
            $ConnectionString = ./Get-AzStorageAccountConnectionString -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -OutputVariable $Config.outputVariable
            $ConnectionString | Should Be "##vso[task.setvariable variable=$($Config.outputVariable);issecret=true]DefaultEndpointsProtocol=https;AccountName=$($Config.storageAccountName);AccountKey=key1;EndpointSuffix=core.windows.net"
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
        }

        It "Secondary Storage Account Key is returned and environment output provided" {
            $ConnectionString = ./Get-AzStorageAccountConnectionString -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -OutputVariable $Config.outputVariable -UseSecondaryKey
            $ConnectionString | Should Be "##vso[task.setvariable variable=$($Config.outputVariable);issecret=true]DefaultEndpointsProtocol=https;AccountName=$($Config.storageAccountName);AccountKey=key2;EndpointSuffix=core.windows.net"
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
        }

    }

}
