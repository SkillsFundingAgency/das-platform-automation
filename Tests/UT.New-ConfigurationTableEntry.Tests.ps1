

Describe "New-ConfigurationTableEntry Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../Infrastructure-Scripts/New-ConfigurationTableEntry/
        Import-Module ./tools/Helpers.psm1 -Force
    }

    Mock Get-ChildItem -MockWith {
        return @(
            @{
                BaseName = "FOO.BAR.Web.schema"
                FullName = "/foo-bar-config/Configuration/foo-bar-web/FOO.BAR.Web.schema.json"
            }
        )
    }

    Mock Build-ConfigurationEntity -MockWith {
        return @{
            PropertyFoo = @{
                ChildPropertyBar = "FooBar"
            }
        } | ConvertTo-Json
    }

    Mock Test-ConfigurationEntity

    Mock New-ConfigurationEntity

    $Params = @{
        SourcePath = "/foo-bar-config/Configuration/foo-bar-web"
        TargetFilename = "FOO.BAR.Web.schema.json"
        StorageAccountName = "fooconfigstr"
        StorageAccountResourceGroup = "foo-config-rg"
        EnvironmentName   = "BAR"
    }

    Context "Passed valid SourcePath, TargetFilename and Storage Account details" {
        It "Should call helper functions to construct and test a configuraton entity and write that to a storage table" {
            ./New-ConfigurationTableEntry.ps1 @Params
            Assert-MockCalled -CommandName Build-ConfigurationEntity -Exactly -Times 1
            Assert-MockCalled -CommandName Test-ConfigurationEntity -Exactly -Times 1
            Assert-MockCalled -CommandName New-ConfigurationEntity -Exactly -Times 1
        }
    }
}
