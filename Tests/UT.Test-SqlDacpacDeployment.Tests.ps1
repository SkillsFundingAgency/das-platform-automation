Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Test-SqlDacpacDeployment Unit Tests" -Tags @("Unit") {

    $ParamsOverridePROD = @{
        Environment = "PROD"
        OverrideBlockOnPossibleDataLoss = $true
    }

    $ENV:ApproveProdOverrideBlockOnPossibleDataLoss = $true

    Context "Test-SqlDacpacDeployment runs with Override for BlockOnPossibleDataLoss set to true and in PROD environment" {
        It "Script is ran with OverrideBlockOnPossibleDataLoss set to true within PROD environment. The following message is given - 'Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'" {
            ./Test-SqlDacpacDeployment @ParamsOverridePROD | Should not Throw
            Assert-MockCalled Write-Verbose -Times 1 -Scope It -ParameterFilter { $InputObject -match "Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'" }
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true" }
        }
    }
}
