Describe "New-ConfigurationTableEntry Build-ConfigurationEntity Helper Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../Infrastructure-Scripts/New-ConfigurationTableEntry/
        #Import-Module ./tools/Helpers.psm1 -Force
    }

    ##TO DO: it's probably not possible to unit test this as mocking will be difficult / impossible in Pester.
    ## integration or functional tests might be the way to go using dummy schema
}

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
