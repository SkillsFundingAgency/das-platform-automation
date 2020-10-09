$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "ConvertTo-AzureDevOpsVariables unit tests" -Tag "Unit" {

    Context "Normal string conversion" {
        It "Should return a string correctly" {
            $Expected = @('Creating Azure DevOps variable foo', '##vso[task.setvariable variable=foo]bar')

            $Output = ./ConvertTo-AzureDevOpsVariables -ARMOutput $Config.ArmOutput
            $Output | Should be $Expected
        }
    }

    Context "Secure string Conversion" {
        It "Should return a securestring correctly" {
            $Expected = @('Creating Azure DevOps variable foo',
                '##vso[task.setvariable variable=foo;issecret=true]bar')

            $Output = ./ConvertTo-AzureDevOpsVariables -ARMOutput $Config.ArmOutputSecure
            $Output | Should be $Expected
        }
    }


    Context "Rename parameter" {
        It "Should change the variable name correctly" {
            $Expected = @('Creating Azure DevOps variable fu from foo',
                '##vso[task.setvariable variable=fu]bar')

            $Output = ./ConvertTo-AzureDevOpsVariables -ARMOutput $Config.ArmOutput -rename @{foo = "fu" }
            $Output | Should be $Expected
        }
    }

}
