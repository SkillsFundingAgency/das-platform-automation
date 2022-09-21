Describe "New-ConfigurationTableEntry Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../Infrastructure-Scripts/New-ConfigurationTableEntry/
        Import-Module ./tools/Helpers.psm1 -Force
    }

    Mock Get-Item -MockWith {
        return @{
            FullName = "/foo-bar-config/Configuration/foo-bar-web/"
            PSIsContainer = $true
        }
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

    Context "Passed valid SourcePath and TargetFilename that contains a single schema and valid Storage Account details" {
        Mock Get-ChildItem -MockWith {
            return @(
                @{
                    BaseName = "FOO.BAR.Web.schema"
                    FullName = "/foo-bar-config/Configuration/foo-bar-web/FOO.BAR.Web.schema.json"
                    Name = "FOO.BAR.Web.schema.json"
                }
            )
        }

        It "Should call helper functions to construct and test a configuraton entity and write that to a storage table" {
            ./New-ConfigurationTableEntry.ps1 @Params
            Assert-MockCalled -CommandName Build-ConfigurationEntity -Exactly -Times 1
            Assert-MockCalled -CommandName Test-ConfigurationEntity -Exactly -Times 1
            Assert-MockCalled -CommandName New-ConfigurationEntity -Exactly -Times 1
        }
    }

    Context "Passed valid SourcePath and TargetFilename that return no schemas and valid Storage Account details" {
        Mock Get-ChildItem

        It "Should throw an error before calling any helper functions" {
            { ./New-ConfigurationTableEntry.ps1 @Params } | Should -Throw "No schemas retrieved from /foo-bar-config/Configuration/foo-bar-web/ matching pattern FOO.BAR.Web.schema.json retrieved"
            Assert-MockCalled -CommandName Build-ConfigurationEntity -Exactly -Times 0
            Assert-MockCalled -CommandName Test-ConfigurationEntity -Exactly -Times 0
            Assert-MockCalled -CommandName New-ConfigurationEntity -Exactly -Times 0
        }
    }

    Context "Passed valid SourcePath and a wildcarded TargetFilename that contains 3 schemas and valid Storage Account details" {
        Mock Get-ChildItem -MockWith {
            return @(
                @{
                    BaseName = "FOO.BAR.Web.schema"
                    FullName = "/foo-bar-config/Configuration/foo-bar-web/FOO.BAR.Web.schema.json"
                    Name = "FOO.BAR.Web.schema.json"
                },
                @{
                    BaseName = "FOO.BAR.Web"
                    FullName = "/foo-bar-config/Configuration/foo-bar-web/FOO.BAR.Web.json"
                    Name = "FOO.BAR.Web.json"
                },
                @{
                    BaseName = "BAR.BAR.Web.schema"
                    FullName = "/foo-bar-config/Configuration/foo-bar-web/BAR.BAR.Web.schema.json"
                    Name = "BAR.BAR.Web.schema.json"
                },
                @{
                    BaseName = "FOO.FOO.Web.schema"
                    FullName = "/foo-bar-config/Configuration/foo-bar-web/FOO.FOO.Web.schema.json"
                    Name = "FOO.FOO.Web.schema.json"
                }
            )
        }

        $Params["TargetFilename"] = "*.schema.json"

        It "Should call helper functions multiple times to construct and test 3 configuraton entities and write those to a storage table" {
            ./New-ConfigurationTableEntry.ps1 @Params
            Assert-MockCalled -CommandName Build-ConfigurationEntity -Exactly -Times 3
            Assert-MockCalled -CommandName Test-ConfigurationEntity -Exactly -Times 3
            Assert-MockCalled -CommandName New-ConfigurationEntity -Exactly -Times 3
        }
    }
}
