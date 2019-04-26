$scripts = Get-ChildItem -Path $PSScriptRoot/../Infrastructure-Scripts/*.ps1 -File

Describe "Script documentation tests" -Tags @("Quality") {

    foreach ($script in $scripts) {

        $help = Get-Help $script.FullName

        Context $script.BaseName {

            It "Has a synopsis" {
                $help.Synopsis | Should Not BeNullOrEmpty
            }

            It "Has a description" {
                $help.Description | Should Not BeNullOrEmpty
            }

            It "Has an example" {
                $help.Examples | Should Not BeNullOrEmpty
            }

            foreach ($parameter in $help.Parameters.Parameter) {
                if ($parameter -notmatch 'whatif|confirm') {
                    It "Has a Parameter description for $($parameter.Name)" {
                        $parameter.Description.Text | Should Not BeNullOrEmpty
                    }
                }
            }
        }
    }
}

Describe "Script code quality tests" -Tags @("Quality") {

    $rules = Get-ScriptAnalyzerRule
    $excludeRules = @(
        "PSAvoidUsingWriteHost",
        "PSAvoidUsingEmptyCatchBlock",
        "PSAvoidUsingPlainTextForPassword"
    )

    foreach ($script in $scripts) {
        Context $script.BaseName {
            forEach ($rule in $rules) {
                It "Should pass Script Analyzer rule $rule" {
                    $result = Invoke-ScriptAnalyzer -Path $script.FullName -IncludeRule $rule -ExcludeRule $excludeRules
                    $result.Count | Should Be 0
                }
            }
        }
    }
}

Describe "Should have a unit test file" -Tags @("Quality") {

    foreach ($script in $scripts) {
        $testName = "$($script.BaseName).Tests.ps1"
        Context "$($script.BaseName)" {
            It "Should have an associated unit test called UTxxx.$testName" {
                $testFile = Get-Item -Path "$PSScriptRoot/UT*$testName" -ErrorAction SilentlyContinue
                $testFile | Should Not Be $null
            }
        }
    }
}
