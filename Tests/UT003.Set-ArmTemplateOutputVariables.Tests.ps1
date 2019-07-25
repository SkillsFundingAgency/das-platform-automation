Set-Location $PSScriptRoot\..\infrastructure-scripts\

Describe "Set-ArmTemplateOutputVariables.ps1 Unit Tests" -Tags @("Unit") {

    Context "The parameter 'ArmOutput' is null or empty" {
        It "Should throw an error" {
            $ArmOutput = $null
            { .\Set-ArmTemplateOutputVariables.ps1 -ArmOutput $ArmOutput } | Should Throw
        }
    }

    Context "The parameter 'ArmOutput' JSON input is invalid" {
        It "Should throw an error" {
            $ArmOutput = '{"testOutput":{"type":"String","value":"testOutputValue"}'
            { .\Set-ArmTemplateOutputVariables.ps1 -ArmOutput $ArmOutput } | Should Throw
        }
    }

    Context "The parameter 'ArmOutput' input was valid" {
        It "Should set variables" {
            $ArmOutput = '{"testOutput":{"type":"String","value":"testOutputValue"}}'
            .\Set-ArmTemplateOutputVariables.ps1 -ArmOutput $ArmOutput | Should Contain "Outputs set as pipeline variables successfully."
        }
    }

}
