$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "New-StorageAccountTable Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "The specified Resource Group was not found in the subscription, throw an error" {
            Mock Get-AzResourceGroup -MockWith { Return $null }
            { ./New-StorageAccountTable -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -TableName $Config.tableName } | Should throw "Resource Group $($Config.resourceGroupName) does not exist."
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
            { ./New-StorageAccountTable -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -TableName $config.tableName } | Should throw "Storage Account $($Config.storageAccountName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
        }
    }

    Context "Resource Group and Storage Account Exists, Create New Table Account" {

        Mock Get-AzResourceGroup -MockWith {
            $ResourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new("West Europe", $null, $Config.resourceGroupName)
            return $ResourceGroupExist
        }

        Mock Get-AzStorageAccount -MockWith {
            $StorageAccountExist = [Microsoft.Azure.Management.Storage.Models.StorageAccount]::new("West Europe", $null, $Config.storageAccountName)
            return $StorageAccountExist
        }

        Mock Get-AzStorageAccountKey -MockWith {
            $ctx = [Microsoft.WindowsAzure.Commands.Common.Storage.LazyAzureStorageContext]
            return $ctx
        }

        It "All Stages of the script should be called " {
            {./New-StorageAccountTable -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -TableName $Config.tableName} | Should -BeLike ""
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 2 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageTable' -Times 1 -Scope It
        }

    }

}
