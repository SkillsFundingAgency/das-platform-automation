$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Wait-AzureDevOpsDeployment.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Wait-AzureDevOpsDeployment Unit Tests" -Tags @("Unit") {

    $ParamsMatched = @{
        EnvironmentId = "150"
        PipelineName = "TEST"
        RunId = "474942"
    }

    $ParamsNonMatched = @{
        EnvironmentId = "150"
        PipelineName = "TEST"
        RunId = "474945"
    }

    Context "Wait-AzureDevOpsDeployment runs and continues with deployment with no sleep" {
        Mock Invoke-RestMethod -MockWith {return $Config}
        Mock Write-Output
        It "Script is run and no blocking deployments are taking place so the following message is given - 'Continuing with deployment.'" {
            { ./Wait-AzureDevOpsDeployment.ps1 @ParamsMatched } | Should not Throw
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "Continuing with deployment." }
        }
    }

    Context "Wait-AzureDevOpsDeployment runs and is blocked for a deployment for more than 30 iterations" {
        Mock Invoke-RestMethod -MockWith {return $Config}
        Mock Write-Output
        It "Script is run with blocking deployments taking place so the following message is given over 30 iterations - 'There is another deployment to this stage currently running in this environment. Retrying in 20 seconds.'" {
            { ./Wait-AzureDevOpsDeployment.ps1 @ParamsNonMatched } | Should not Throw
            Assert-MockCalled Write-Output -Times 2 -Scope It -ParameterFilter { $InputObject -match "There is another deployment to this stage currently running in this environment. Retrying in 20 seconds." }
            Assert-MockCalled Write-Output -Times 1 -Scope It -ParameterFilter { $InputObject -match "Retry limit has been reached - Continuing with deployment." }
        }
    }
}
