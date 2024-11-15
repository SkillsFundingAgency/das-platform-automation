Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Approve-SqlDacpacDeploymentDataLoss Unit Tests" -Tags @("Unit") {

    $ParamsOverridePROD = @{
        Environment = "PROD"
        OverrideBlockOnPossibleDataLoss = $true
    }
    $ParamsNoOverridePROD = @{
        Environment = "PROD"
        OverrideBlockOnPossibleDataLoss = $false
    }
    $ParamsOverrideMO = @{
        Environment = "MO"
        OverrideBlockOnPossibleDataLoss = $true
    }
    $ParamsNoOverrideMO = @{
        Environment = "MO"
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

    Context "Approve-SqlDacpacDeploymentDataLoss runs with override for BlockOnPossibleDataLoss set to true and in PROD environment" {
        $ENV:ApprovePRODOverrideBlockOnPossibleDataLoss = $true
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. SetBlockOnPossibleDataLossArgument is returned as true" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsOverridePROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override for BlockOnPossibleDataLoss approved for PROD, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
    Context "Approve-SqlDacpacDeploymentDataLoss runs with override for BlockOnPossibleDataLoss set to true and in PROD environment - but approval is set to false" {
        $ENV:ApprovePRODOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment but with no approval. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsOverridePROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override for BlockOnPossibleDataLoss not approved for PROD, deploying DACPAC with default arguments" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }
    Context "Approve-SqlDacpacDeploymentDataLoss runs with no override for BlockOnPossibleDataLoss and in PROD environment" {
        $ENV:ApprovePRODOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to false within PROD environment. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsNoOverridePROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override BlockOnPossibleDataLoss not requested" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }

    Context "Approve-SqlDacpacDeploymentDataLoss runs with override for BlockOnPossibleDataLoss set to true and in MO environment" {
        $ENV:ApproveMOOverrideBlockOnPossibleDataLoss = $true
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within MO environment. SetBlockOnPossibleDataLossArgument is returned as true" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsOverrideMO } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override for BlockOnPossibleDataLoss approved for MO, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }

    Context "Approve-SqlDacpacDeploymentDataLoss runs with override for BlockOnPossibleDataLoss set to true and in MO environment - but approval is set to false" {
        $ENV:ApproveMOOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within MO environment but with no approval. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsOverrideMO } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override for BlockOnPossibleDataLoss not approved for MO, deploying DACPAC with default arguments" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }

    Context "Approve-SqlDacpacDeploymentDataLoss runs with no override for BlockOnPossibleDataLoss and in MO environment" {
        $ENV:ApproveMOOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to false within MO environment. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsNoOverrideMO } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override BlockOnPossibleDataLoss not requested" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }

    Context "Approve-SqlDacpacDeploymentDataLoss runs with override for BlockOnPossibleDataLoss set to true and in AT environment" {
        $ENV:ApprovePRODOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within AT environment. SetBlockOnPossibleDataLossArgument is returned as true" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsOverrideNonPROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Environment is not MO or PROD, overriding BlockOnPossibleDataLoss" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
    Context "Approve-SqlDacpacDeploymentDataLoss runs with override for BlockOnPossibleDataLoss set to true and in AT environment" {
        $ENV:ApprovePRODOverrideBlockOnPossibleDataLoss = $false
        Mock Write-Output
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to false within the AT environment. SetBlockOnPossibleDataLossArgument is returned as false" {
            { ./Approve-SqlDacpacDeploymentDataLoss.ps1 @ParamsNoOverrideNonPROD } | Should not Throw
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "Override BlockOnPossibleDataLoss not requested" }
            Assert-MockCalled Write-Output -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }
}
