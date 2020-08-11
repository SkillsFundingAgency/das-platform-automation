$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

$MockTemplateFilePath = "$PSScriptRoot/Resources/mock.template.json"
$MockParametersFilePath = "$PSScriptRoot/Resources/mock.template.parameters.json"

function Set-MockEnvironment {
    $env:String = $Config.String
    $env:Integer = $Config.Integer
    $env:Boolean = $Config.Boolean
    $env:Object = $Config.Object
    $env:Array = $Config.Array
    $env:ObjectArray = $Config.ObjectArray
}

function Clear-MockEnvironment {
    Remove-Item -Path @(
        "env:String",
        "env:Integer",
        "env:Boolean",
        "env:Object",
        "env:Array",
        "env:ObjectArray"
    ) -Force -ErrorAction "SilentlyContinue"
}

Describe "New-ParametersFile Unit Tests" {

    Context "When passed a valid arm template with required environment variables" {

        Set-MockEnvironment

        It "Should succesfully save a file to the given path" {
            Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
            ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath
            Test-Path -Path $MockParametersFilePath | Should Be True
        }

        It "Should create a valid json file that can be deserialized" {
            Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
            ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath
            { Get-Content -Path $MockParametersFilePath -Raw | ConvertFrom-Json } | Should Not Throw
        }

        It "Should return the same parmeters as the arm template" {
            Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
            ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath
            $TemplateFileParameterNames = (Get-Content -Path $MockTemplateFilePath -Raw | ConvertFrom-Json).Parameters.PSObject.Properties.Name | Sort-Object
            $ParametersFileParameterNames = (Get-Content -Path $MockParametersFilePath -Raw | ConvertFrom-Json).Parameters.PSObject.Properties.Name | Sort-Object
            $TemplateFileParameterNames | Should -Be $ParametersFileParameterNames
        }

        It "Should return values in the parameters file" {
            Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
            ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath
            $TemplateFileParameters = (Get-Content -Path $MockTemplateFilePath -Raw | ConvertFrom-Json).Parameters.PSObject.Properties | Sort-Object
            $ParametersFileParameters = (Get-Content -Path $MockParametersFilePath -Raw | ConvertFrom-Json).Parameters.PSObject.Properties | Sort-Object

            foreach ($Parameter in $TemplateFileParameters) {
                $ParameterValue = ($ParametersFileParameters | Where-Object { $_.Name -eq $Parameter.Name }).Value.Value
                if (!$ParameterValue -and $Parameter.Value.Type -eq "array") {
                    $ParameterValue = @()
                }
                $ParameterValue | Should Not be NullOrEmpty
            }

        }

        Clear-MockEnvironment

    }

    Context "When passed an invalid value for an integer" {

        Set-MockEnvironment
        $env:Integer = $Config.String

        It "Should throw an exception" {
            {
                Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
                ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath | Should Throw
            }
        }

        Clear-MockEnvironment

    }

    Context "When passed an invalid value for a boolean" {

        Set-MockEnvironment
        $env:Boolean = $Config.String

        It "Should throw an exception" {
            {
                Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
                ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath | Should Throw
            }
        }

        Clear-MockEnvironment
    }

    Context "When passed an invalid value for an object" {

        Set-MockEnvironment
        $env:Object = $Config.String

        It "Should throw an exception" {
            {
                Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
                ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath | Should Throw
            }
        }

        Clear-MockEnvironment
    }

    Context "When passed an invalid value for an array" {

        Set-MockEnvironment
        $env:Array = $Config.String

        It "Should throw an exception" {
            {
                Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
                ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath | Should Throw
            }
        }

        Clear-MockEnvironment

    }

    Context "When passed an invalid value for an array of objects" {

        Set-MockEnvironment
        $env:ObjectArray = $Config.String

        It "Should throw an exception" {
            {
                Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
                ./New-ParametersFile -TemplateFilePath $MockTemplateFilePath -ParametersFilePath $MockParametersFilePath | Should Throw
            }
        }

        Clear-MockEnvironment

    }

    Context "When passed an invalid arm template" {

        Set-MockEnvironment

        It "Should throw an exception" {
            {
                Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
                ./New-ParametersFile -TemplateFilePath $PSScriptRoot -ParametersFilePath $MockParametersFilePath | Should Throw
            }
        }

        Clear-MockEnvironment
    }

    Remove-Item -Path $MockParametersFilePath -ErrorAction "SilentlyContinue"
}
