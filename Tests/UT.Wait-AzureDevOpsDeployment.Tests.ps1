$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Wait-AzureDevOpsDeployment.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Wait-AzureDevOpsDeployment Unit Tests" -Tags @("Unit") {

    $ParamsMatched = @{
        AzureDevOpsOrganisationUri = "https://dev.azure.com/foobarorg/"
        AzureDevOpsProjectName = "project-foo"
        EnvironmentId = "150"
        PipelineName = "TEST"
        RunId = "474942"
    }

    $ParamsNonMatched = @{
        AzureDevOpsOrganisationUri = "https://dev.azure.com/foobarorg/"
        AzureDevOpsProjectName = "project-foo"
        EnvironmentId = "150"
        PipelineName = "TEST"
        RunId = "474945"
        SleepTime = 1
    }

    Context "Wait-AzureDevOpsDeployment runs and continues with deployment with no sleep" {
        Mock Invoke-RestMethod -MockWith {return $Config}
        Mock Write-Output
        It "Script is run and no blocking deployments are taking place so the following message is given - 'Continuing with deployment.'" {
            { ./Wait-AzureDevOpsDeployment.ps1 @ParamsMatched } | Should not Throw
            Assert-MockCalled Write-Output -Times 1 -Exactly -Scope It -ParameterFilter { $InputObject -match "Continuing with deployment." }
        }
    }

    Context "Wait-AzureDevOpsDeployment runs and is blocked for a deployment for more than 30 iterations" {
        Mock Invoke-RestMethod -MockWith {return $Config}
        Mock Write-Output
        Mock Write-Warning
        It "Script is run with blocking deployments taking place so the following message is given over 30 iterations - 'There is another deployment to this stage currently running in this environment. Retrying in 1 second(s).'" {
            { ./Wait-AzureDevOpsDeployment.ps1 @ParamsNonMatched } | Should throw
            Assert-MockCalled Write-Output -Times 30 -Exactly -Scope It -ParameterFilter { $InputObject -match "There is another deployment to this stage currently running in this environment. Retrying in 1 second(s)." }
            Assert-MockCalled Write-Warning -Times 1 -Exactly -Scope It -ParameterFilter { $Message -match "Retry limit has been reached, terminating deployment - please retry later" }
        }
    }
}
