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
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. The following message is given - 'Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.''" {
            ./Test-SqlDacpacDeployment @ParamsOverridePROD | Should not Throw
            Assert-MockCalled Write-Verbose -Times 1 -Scope It -ParameterFilter { $InputObject -match "Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'" }
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
    Context "Test-SqlDacpacDeployment runs with no override for BlockOnPossibleDataLoss and in PROD environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $false
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. The following message is given - 'Override for BlockOnPossibleDataLoss not approved, deploying DACPAC with default arguments'" {
            ./Test-SqlDacpacDeployment @ParamsNoOverridePROD | Should not Throw
            Assert-MockCalled Write-Verbose -Times 1 -Scope It -ParameterFilter { $InputObject -match "Override for BlockOnPossibleDataLoss not approved, deploying DACPAC with default arguments" }
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }
    Context "Test-SqlDacpacDeployment runs with override for BlockOnPossibleDataLoss set to true and in AT environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $false
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. The following message is given - 'Environment is not PROD, overriding BlockOnPossibleDataLoss'" {
            ./Test-SqlDacpacDeployment @ParamsNoOverridePROD | Should not Throw
            Assert-MockCalled Write-Verbose -Times 1 -Scope It -ParameterFilter { $InputObject -match "Environment is not PROD, overriding BlockOnPossibleDataLoss" }
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
    Context "Test-SqlDacpacDeployment runs with override for BlockOnPossibleDataLoss set to true and in AT environment" {
        $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $false
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. The following message is given - 'Override BlockOnPossibleDataLoss not requested'" {
            ./Test-SqlDacpacDeployment @ParamsNoOverrideNonPROD | Should not Throw
            Assert-MockCalled Write-Verbose -Times 1 -Scope It -ParameterFilter { $InputObject -match "Override BlockOnPossibleDataLoss not requested" }
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false" }
        }
    }
}
