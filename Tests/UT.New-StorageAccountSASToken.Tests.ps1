$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Scripts\Infrastructure\

Describe "New-StorageAccountSASToken Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "The specified Resource Group was not found in the subscription, throw an error" {
            Mock Get-AzResourceGroup -MockWith { Return $null }
            { ./New-StorageAccountSASToken -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -Service $Config.storageAccountSASTokenService -ResourceType $Config.storageAccountSASTokenResourceType -Permissions $Config.storageAccountSASTokenPermissions -ExpiryInMinutes $Config.storageAccountSASTokenExpiryMinutes } | Should throw "Resource Group $($Config.resourceGroupName) does not exist."
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
            { ./New-StorageAccountSASToken -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -Service $Config.storageAccountSASTokenService -ResourceType $Config.storageAccountSASTokenResourceType -Permissions $Config.storageAccountSASTokenPermissions -ExpiryInMinutes $Config.storageAccountSASTokenExpiryMinutes } | Should throw "Storage Account $($Config.storageAccountName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
        }
    }

    Context "Resource Group and Storage Account exists, return Storage Account SAS tokens" {

        Mock Get-AzResourceGroup -MockWith {
            $ResourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new($Config.location, $null, $Config.resourceGroupName)
            return $ResourceGroupExist
        }

        Mock Get-AzStorageAccount -MockWith {
            $StorageAccountExist = [Microsoft.Azure.Management.Storage.Models.StorageAccount]::new($Config.location, $null, $Config.storageAccountName)
            return $StorageAccountExist
        }

        Mock Get-AzStorageAccountKey -MockWith {
            $KeyArr = @()
            1..2 | ForEach-Object {
                $KeyArr += [Microsoft.Azure.Management.Storage.Models.StorageAccountKey]::new("Key$_", "Key$_", 1)
            }
            return $KeyArr
        }

        Mock New-AzStorageContext -MockWith {
            $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
            return $StorageContext
        }

        Mock New-AzStorageAccountSASToken -MockWith {
            $SASToken = $Config.storageAccountSASToken
            return $SASToken
        }

        It "SAS token is returned and environment output provided" {

            $SASTokenOutput = ./New-StorageAccountSASToken -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -Service $Config.storageAccountSASTokenService -ResourceType $Config.storageAccountSASTokenResourceType -Permissions $Config.storageAccountSASTokenPermissions -ExpiryInMinutes $Config.storageAccountSASTokenExpiryMinutes
            $SASTokenOutput | Should Be "##vso[task.setvariable variable=$($Config.storageAccountSASTokenOutputVariable);issecret=true]$($Config.storageAccountSASToken)"
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageAccountSASToken' -Times 1 -Scope It
        }

        It "SAS token is returned with the ? character removed from the start of the token, and environment output provided" {

            $SASTokenOutput = ./New-StorageAccountSASToken -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -Service $Config.storageAccountSASTokenService -ResourceType $Config.storageAccountSASTokenResourceType -Permissions $Config.storageAccountSASTokenPermissions -ExpiryInMinutes $Config.storageAccountSASTokenExpiryMinutes -GenerateForSQLExternalDatasource
            $SASTokenOutput | Should Be "##vso[task.setvariable variable=$($Config.storageAccountSASTokenOutputVariable);issecret=true]$($Config.storageAccountSASTokenGenerateForSQLExternalDatasource)"
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageAccountSASToken' -Times 1 -Scope It
        }

    }

}
