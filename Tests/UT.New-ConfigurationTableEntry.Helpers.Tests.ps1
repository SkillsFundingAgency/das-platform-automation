# note: helper functions that directly rely on Newtonsoft.Json.Schema library are tested in integration tests
# helper functions that indirectly rely on Newtonsoft.Json.Schema (ie those that consume it's results) are not directly tested but they are called during integration testing

Describe "New-ConfigurationTableEntry New-ConfigurationEntity Helper Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../Infrastructure-Scripts/New-ConfigurationTableEntry/
        Import-Module ./tools/Helpers.psm1 -Force
    }

    Mock Get-StorageAccountKey -ModuleName Helpers -MockWith {
        return "bm90LWEtcmVhbC1hY2NvdW50LWtleQ=="
    }

    Mock Get-AzStorageTable -ModuleName Helpers -MockWith {
        return @{
            CloudTable = @{
                Name = "Configuration"
            }
        }
    }

    Mock New-AzStorageTable -ModuleName Helpers

    Mock Get-AzTableRow -ModuleName Helpers -MockWith {
        return @{
            Data = @{ PropertyFoo = @{ ChildPropertyBar = "FooFoo" } } | ConvertTo-Json
        }
    }

    Mock Update-AzTableRow -ModuleName Helpers

    Mock Add-AzTableRow -ModuleName Helpers

    Mock Write-Host -ModuleName Helpers

    $Params = @{
        StorageAccountName = "fooconfigstr"
        StorageAccountResourceGroup = "foo-config-rg"
        TableName = "Configuration"
        PartitionKey = "FOO"
        RowKey = "FOO.BAR.Web_1.0"
        Configuration = @{ PropertyFoo = @{ ChildPropertyBar = "FooBar" } } | ConvertTo-Json
    }

    Context "Storage table and row already exist" {
        It "Should update the existing row in the existing table" {
            New-ConfigurationEntity @Params
            Assert-MockCalled -CommandName New-AzStorageTable -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Update-AzTableRow -ModuleName Helpers -Exactly -Times 1
            Assert-MockCalled -CommandName Add-AzTableRow -ModuleName Helpers -Exactly -Times 0
        }
    }

    Context "Storage table exists but row doesn't" {
        Mock Get-AzTableRow -ModuleName Helpers

        It "Should add a new row in the existing table" {
            New-ConfigurationEntity @Params
            Assert-MockCalled -CommandName New-AzStorageTable -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Update-AzTableRow -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Add-AzTableRow -ModuleName Helpers -Exactly -Times 1
        }
    }

    Context "Storage table exists but row doesn't and there is an error trying to add the row" {
        Mock Get-AzTableRow -ModuleName Helpers

        Mock Add-AzTableRow -ModuleName Helpers -MockWith {
            throw
        }

        It "Should throw an error and not write out a success message" {
            { New-ConfigurationEntity @Params } | Should -Throw
            Assert-MockCalled -CommandName New-AzStorageTable -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Update-AzTableRow -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Add-AzTableRow -ModuleName Helpers -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Host -ModuleName Helpers -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Host -ModuleName Helpers -ParameterFilter { $Object -match "^Configuration succesfully added to.*"} -Exactly -Times 0
        }
    }

    Context "Storage table and row already exist but there is an error trying to update the row" {
        Mock Update-AzTableRow -ModuleName Helpers -MockWith {
            throw
        }

        It "Should throw an error and not write out a success message" {
            { New-ConfigurationEntity @Params } | Should -Throw
            Assert-MockCalled -CommandName New-AzStorageTable -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Update-AzTableRow -ModuleName Helpers -Exactly -Times 1
            Assert-MockCalled -CommandName Add-AzTableRow -ModuleName Helpers -Exactly -Times 0
            Assert-MockCalled -CommandName Write-Host -ModuleName Helpers -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Host -ModuleName Helpers -ParameterFilter { $Object -match "^Configuration succesfully added to.*"} -Exactly -Times 0
        }
    }
}

Describe "New-ConfigurationTableEntry Get-StorageAccountKey Helper Unit Tests" -Tags @("Unit") {
    Context "Passed a valid storage account name and resource group" {
        Mock Get-AzResourceGroup -ModuleName Helpers -MockWith {
            return @{
                Name = "foo-bar-rg"
            }
        }

        Mock Get-AzStorageAccount -ModuleName Helpers -MockWith {
            return @{
                Name = "foobarstr"
            }
        }

        Mock Get-AzStorageAccountKey -ModuleName Helpers -MockWith {
            return @(
                @{
                    Value = "not-a-real-account-key"
                },
                @{
                    Value = "not-a-real-secondary-key"
                }
            )
        }

        $Params = @{
            ResourceGroup = "foo-bar-rg"
            StorageAccountName = "foobarstr"
        }

        It "Should return an account key" {
            $Result = Get-StorageAccountKey @Params
            $Result | Should -Be "not-a-real-account-key"
        }
    }
}
