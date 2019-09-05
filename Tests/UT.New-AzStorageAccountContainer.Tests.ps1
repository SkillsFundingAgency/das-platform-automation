$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "New-AzStorageAccountContainer.ps1 Unit Tests" -Tags @("Unit") {

    Context "Storage Account does not exist" {

        It "The specified Storage Account was not found in the subscription, throw an error" {
            Mock Get-AzResource -MockWith { Return $null }
            { .\New-AzStorageAccountContainer.ps1 -Location $Config.location -Name $Config.storageAccountName -ContainerName $Config.containerName } | Should throw "Could not find storage account $($Config.storageAccountName)"
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        }

    }

    Context "Storage Account exists" {

        Mock Get-AzResource -MockWith {
            $StorageAccountResource = New-Object psobject -Property @{
                ResourceGroupName = $Config.resourceGroupName
            }
            return $StorageAccountResource
        }

        Mock Get-AzStorageAccount -MockWith {
            $StorageAccount = [Microsoft.Azure.Management.Storage.Models.StorageAccount]::new("West Europe", $null, $Config.storageAccountName)
            return $StorageAccount
        }

        Mock Get-AzStorageAccountKey -MockWith {
            $StorageAccountKey = [Microsoft.Azure.Management.Storage.Models.StorageAccountKey]::new("Key", "Key", 1)
            return $StorageAccountKey
        }

        Mock New-AzStorageContext -MockWith { return $null }
        Mock Get-AzStorageContainer -MockWith { return $null }
        Mock New-AzStorageContainer -MockWith { return $null }

        It "New Storage Container is created and StorageConnectionString environment variable is set" {
            $ConnectionString = .\New-AzStorageAccountContainer.ps1 -Location $Config.location -Name $Config.storageAccountName -ContainerName $Config.containerName
            $ConnectionString | Should Be "##vso[task.setvariable variable=StorageConnectionString; issecret=true;]DefaultEndpointsProtocol=https;AccountName=$($Config.storageAccountName);AccountKey=key"
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageContainer' -Times 1 -Scope It
        }

    }

}
