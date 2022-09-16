Describe "New-ConfigurationTableEntry.Helper Integration Tests" -Tags @("Integration") {

    BeforeAll {
        Set-Location $PSScriptRoot/../Infrastructure-Scripts/New-ConfigurationTableEntry/
        Import-Module ./tools/Helpers.psm1 -Force
    }

    Context "A valid schema and complete set of environment variables exists" {
        if (!$ENV:TF_BUILD) {
            Import-Module powershell-yaml
            $EnvironmentVariables = Get-Content ../../Tests/Resources/mock-configuration-schema/mock-variables.yml | ConvertFrom-Yaml
            foreach ($Key in $EnvironmentVariables.variables.keys) {
                New-Variable -Name $Key -Value $EnvironmentVariables.variables[$Key] -Scope Global -Force
            }
        }

        $Params = @{
            SchemaDefinitionPath = "$PSScriptRoot/Resources/mock-configuration-schema/mock-configuration-schema.json"
        }

        It "Build-ConfigurationEntity should return a JSON object that matches expected-configuration.json" {
            $ExpectedConfiguration = Get-Content -Path $PSScriptRoot/Resources/mock-configuration-schema/expected-configuration.json -Raw | ConvertFrom-Json
            $Result = Build-ConfigurationEntity @Params
            Compare-Object -ReferenceObject $ExpectedConfiguration -DifferenceObject ($Result | ConvertFrom-Json) -Property MockObject | Should -BeNullOrEmpty
            foreach ($ConfigProperty in $ExpectedConfiguration | Get-Member -MemberType NoteProperty) {
                Compare-Object -ReferenceObject $ExpectedConfiguration -DifferenceObject ($Result | ConvertFrom-Json) -Property $ConfigProperty.Name | Should -BeNullOrEmpty
            }
            foreach ($ConfigObjectProperty in $ExpectedConfiguration.MockObject | Get-Member -MemberType NoteProperty) {
                Compare-Object -ReferenceObject $ExpectedConfiguration.MockObject -DifferenceObject ($Result | ConvertFrom-Json).MockObject -Property $ConfigObjectProperty.Name | Should -BeNullOrEmpty
            }
            Compare-Object -ReferenceObject $ExpectedConfiguration.MockParentObject.MockChildObject -DifferenceObject ($Result | ConvertFrom-Json).MockParentObject.MockChildObject -Property MockChildString | Should -BeNullOrEmpty
        }

        It "Test-ConfigurationEntity should not throw an error" {

            $Configuration = Build-ConfigurationEntity @Params
            $Params["Configuration"] = $Configuration
            { Test-ConfigurationEntity @Params } | Should -Not -Throw
        }
    }

    Context "A valid schema and incomplete set of environment variables exists" {
        if (!$ENV:TF_BUILD) {
            Import-Module powershell-yaml
            $EnvironmentVariables = Get-Content ../../Tests/Resources/mock-configuration-schema/mock-variables.yml | ConvertFrom-Yaml
            foreach ($Key in $EnvironmentVariables.variables.keys) {
                New-Variable -Name $Key -Value $EnvironmentVariables.variables[$Key] -Scope Global -Force
            }
        }

        It "Build-ConfigurationEntity should throw an error" {
            $Params = @{
                SchemaDefinitionPath = "$PSScriptRoot/Resources/mock-configuration-schema/mock-configuration-schema-missing-envvar.json"
            }
            { Build-ConfigurationEntity @Params } | Should -Throw -ExpectedMessage "No environment variable found and no default value set in schema"
        }
    }
}
