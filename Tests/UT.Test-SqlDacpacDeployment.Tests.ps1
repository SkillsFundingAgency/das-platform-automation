Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Test-SqlDacpacDeployment Unit Tests" -Tags @("Unit") {

    $ParamsOverridePROD = @{
        Environment = "PROD"
        OverrideBlockOnPossibleDataLoss = $true
    }
    $ParamsNoOverridePROD = @{
        Environment = "PROD"
        OverrideBlockOnPossibleDataLoss = $false
    }
    $ParamsOverrideNonPROD = @{
        Environment = "AT"
        OverrideBlockOnPossibleDataLoss = $true
    }
    $ParamsNoOverrideNonPROD = @{
        Environment = "AT"
        OverrideBlockOnPossibleDataLoss = $false
    }

    Context "Test-SqlDacpacDeployment runs with override for BlockOnPossibleDataLoss set to true and in PROD environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $true
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. SetBlockOnPossibleDataLossArgument is returned as true" {
            { ./Test-SqlDacpacDeployment.ps1 @ParamsOverridePROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
    Context "Test-SqlDacpacDeployment runs with no override for BlockOnPossibleDataLoss and in PROD environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to false within PROD environment. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Test-SqlDacpacDeployment @ParamsNoOverridePROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }
    Context "Test-SqlDacpacDeployment runs with override for BlockOnPossibleDataLoss set to true and in AT environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within AT environment. SetBlockOnPossibleDataLossArgument is returned as true" {
            { ./Test-SqlDacpacDeployment @ParamsOverrideNonPROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
    Context "Test-SqlDacpacDeployment runs with override for BlockOnPossibleDataLoss set to true and in AT environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to false within the AT environment. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Test-SqlDacpacDeployment @ParamsNoOverrideNonPROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }
}
