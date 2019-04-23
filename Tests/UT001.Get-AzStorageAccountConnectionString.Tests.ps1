# --- Import configuration
$config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json

# --- Import the Get-AzStorageAccountConnectionString function
Import-Module $PSScriptRoot\..\Infrastructure-Scripts\Get-AzStorageAccountConnectionString.ps1 -Force

Describe "Get-AzStorageAccountConnectionString Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "The specified Resource Group was not found in the subscription, throw an error"{
            Mock Get-AzResourceGroup -MockWith { Return $null }
            { Get-AzStorageAccountConnectionString -ResourceGroup $config.resourceGroupName -StorageAccount $config.storageAccountName -OutputVariable $config.outputVariable  } | Should throw "Resource Group $($config.resourceGroupName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
        }
    }

    Context "Resource Group exists but not Storage Account" {
        It "The specified Storage Account was not found in the subscription, throw an error" {
            Mock Get-AzResourceGroup -MockWith {
                $resourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new($config.location,$null,$config.resourceGroupName)
                return $resourceGroupExist
            }
            Mock Get-AzStorageAccount -MockWith { Return $null }
            { Get-AzStorageAccountConnectionString -ResourceGroup $config.resourceGroupName -StorageAccount $config.storageAccountName -OutputVariable $config.outputVariable  } | Should throw "Storage Account $($config.storageAccountName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
        }
    }

    Context "Resource Group and Storage Account Exists, Return Storage Account Connection Strings" {

		Mock Get-AzResourceGroup -MockWith {
			$resourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new("West Europe",$null,$config.resourceGroupName)
			return $resourceGroupExist
		}

		Mock Get-AzStorageAccount -MockWith {
			$storageAccountExist = [Microsoft.Azure.Management.Storage.Models.StorageAccount]::new("West Europe",$null,$config.storageAccountName)
			return $storageAccountExist
		}

		Mock Get-AzStorageAccountKey -MockWith {
			$keyArr = @()
			1..2 | ForEach-Object{
				$keyArr += [Microsoft.Azure.Management.Storage.Models.StorageAccountKey]::new("Key$_","Key$_",1)
			}
			return $keyArr
		}

        It "Primary Storage Account Key is returned and environment output provided"{
			$ConnectionString = Get-AzStorageAccountConnectionString -ResourceGroup $config.resourceGroupName -StorageAccount $config.storageAccountName -OutputVariable $config.outputVariable
			$ConnectionString | Should Be "##vso[task.setvariable variable=$($config.outputVariable);issecret=true]DefaultEndpointsProtocol=https;AccountName=$($config.storageAccountName);AccountKey=key1;EndpointSuffix=core.windows.net"
			Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
			Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
			Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
		}

        It "Secondary Storage Account Key is returned and environment output provided"{
			$ConnectionString = Get-AzStorageAccountConnectionString -ResourceGroup $config.resourceGroupName -StorageAccount $config.storageAccountName -OutputVariable $config.outputVariable -UseSecondaryKey
			$ConnectionString | Should Be "##vso[task.setvariable variable=$($config.outputVariable);issecret=true]DefaultEndpointsProtocol=https;AccountName=$($config.storageAccountName);AccountKey=key2;EndpointSuffix=core.windows.net"
			Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
			Assert-MockCalled -CommandName 'Get-AzStorageAccount' -Times 1 -Scope It
			Assert-MockCalled -CommandName 'Get-AzStorageAccountKey' -Times 1 -Scope It
		}

	}

}
