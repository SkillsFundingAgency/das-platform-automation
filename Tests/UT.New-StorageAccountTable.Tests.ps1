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

    Context "Resource Group and Storage Account Exists, Table name does not exists." {

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

        Mock New-AzStorageContext -MockWith  {
            $storageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
            return $storageContext
        }

        Mock Get-AzStorageTable -MockWith {
            $ErrorId = ' ResourceNotFoundException,Microsoft.WindowsAzure.Commands.Storage.Table.Cmdlet.GetAzureStorageTableCommand'
            $TargetObject = 'ResourceNotFoundException'
            $ErrorCategory = [System.Management.Automation.ErrorCategory]::OpenError
            $ErrorMessage = "Get-AzureStorageTable : Can not find table $($Config.tableName)"
            $Exception = New-Object -TypeName System.InvalidOperationException -ArgumentList $ErrorMessage
            Write-Error -ErrorId $ErrorId -TargetObject $TargetObject -Category $ErrorCategory -Message $ErrorMessage -Exception $Exception

        }

        Mock  New-AzStorageTable -MockWith {
            $value = "Table End Point: $($Config.storageAccountName)"
            return $value
        }

        It "All Stages of the script should be called " {
            ./New-StorageAccountTable -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -TableName $Config.tableName
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName  'Get-AzStorageAccountKey' -Times 1 -Scope It
            Assert-MockCalled -CommandName  'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName  'Get-AzStorageTable' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageTable' -Times 1 -Scope It
        }

    }
    Context "Resource Group and Storage Account Exists, Table Name already exists" {

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

        Mock New-AzStorageContext -MockWith  {
            $storageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
            return $storageContext
        }

        Mock Get-AzStorageTable -MockWith {
            $tableName = $Config.tableName
            return $tableName
        }

        Mock  New-AzStorageTable -MockWith {
            $value = "Table End Point: $($Config.storageAccountName)"
            return $value
        }

        It "All Stages of the script should be called " {
            ./New-StorageAccountTable -ResourceGroup $Config.resourceGroupName -StorageAccount $Config.storageAccountName -TableName $Config.tableName
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName  'Get-AzStorageAccountKey' -Times 1 -Scope It
            Assert-MockCalled -CommandName  'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName  'Get-AzStorageTable' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzStorageTable' -Times 0 -Scope It
        }

    }
}
