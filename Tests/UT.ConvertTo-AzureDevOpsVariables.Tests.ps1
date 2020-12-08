$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "ConvertTo-AzureDevOpsVariables unit tests" -Tag "Unit" {

    Context "Normal string conversion" {
        It "Should return a string correctly" {
            $Expected = @('Creating Azure DevOps variables FOO and FOO',
                '##vso[task.setvariable variable=foo;isOutput=false]bar',
                '##vso[task.setvariable variable=foo;isOutput=true]bar')

            $Output = ./ConvertTo-AzureDevOpsVariables -ARMOutput $Config.ArmOutput
            $Output | Should be $Expected
        }
    }

    Context "Secure string Conversion" {
        It "Should return a securestring correctly" {
            $Expected = @('Creating Azure DevOps variables FOO and FOO',
                '##vso[task.setvariable variable=foo;issecret=true;isOutput=false]bar',
                '##vso[task.setvariable variable=foo;issecret=true;isOutput=true]bar')

            $Output = ./ConvertTo-AzureDevOpsVariables -ARMOutput $Config.ArmOutputSecure
            $Output | Should be $Expected
        }
    }


    Context "Rename parameter" {
        It "Should change the variable name correctly" {
            $Expected = @('Creating Azure DevOps variables FU and FU from foo',
            '##vso[task.setvariable variable=fu;isOutput=false]bar',
            '##vso[task.setvariable variable=fu;isOutput=true]bar')

            $Output = ./ConvertTo-AzureDevOpsVariables -ARMOutput $Config.ArmOutput -Rename @{foo = "fu" }
            $Output | Should be $Expected
        }
    }

}
