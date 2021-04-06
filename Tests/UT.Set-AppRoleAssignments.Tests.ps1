$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\Set-AppRoleAssignments

Describe "Set-AppRoleAssignments Unit Tests" -Tags @("Unit") {

    Context "Environment is invalid" {
        It "The extracted environment from app service name is invalid, throw an error" {

            $AppServiceName = "das-poc-ui-as"
            { ./Set-AppRoleAssignments -AppRegistrationConfigurationFilePath "$PSScriptRoot\..\Infrastructure-Scripts\Set-AppRoleAssignments\config.json" -AppServiceName $AppServiceName -Tenant $Config.Tenant -DryRun $true} | Should Throw "Environment retrieved from app service name not valid"

        }
    }

    Context "Environment is valid but no app registrations to process" {
        It "No app registrations found to process, throw an error" {

            $AppServiceName = "das-test-foobar-as"
            { ./Set-AppRoleAssignments -AppRegistrationConfigurationFilePath "$PSScriptRoot\..\Infrastructure-Scripts\Set-AppRoleAssignments\config.json" -AppServiceName $AppServiceName -Tenant $Config.Tenant -DryRun $true } | Should Throw "No app registrations to process. Check app service name or update configuration."

        }
    }

    Context "Get a service principal" {
        It "Retrieve multiple service principals" {

            Mock Get-ServicePrincipal -MockWith { return @("", "") }
            $AppServiceName = "das-test-ui-as"

            { ./Set-AppRoleAssignments -AppRegistrationConfigurationFilePath "$PSScriptRoot\..\Infrastructure-Scripts\Set-AppRoleAssignments\config.json" -AppServiceName $AppServiceName -Tenant $Config.Tenant -DryRun $true } | Should Throw "-> Found a duplicate app registrations with the same display name. Investigate"
            Assert-MockCalled Get-ServicePrincipal -Times 1

        }

        It "No service principal found" {

            Mock Get-ServicePrincipal -MockWith { return $null }
            Mock Write-Output {}
            $AppServiceName = "das-test-ui-as"

            { ./Set-AppRoleAssignments -AppRegistrationConfigurationFilePath "$PSScriptRoot\..\Infrastructure-Scripts\Set-AppRoleAssignments\config.json" -AppServiceName $AppServiceName -Tenant $Config.Tenant -DryRun $true } | Should Not Throw
            Assert-MockCalled Write-Output -Times 2 -Scope It -ParameterFilter { $InputObject -match "not found in AAD - Creating" }
        }

        It "Single service principal found" {

            Mock Get-ServicePrincipal -MockWith { @("") }
            Mock Write-Output { }
            $AppServiceName = "das-test-ui-as"

            { ./Set-AppRoleAssignments -AppRegistrationConfigurationFilePath "$PSScriptRoot\..\Infrastructure-Scripts\Set-AppRoleAssignments\config.json" -AppServiceName $AppServiceName -Tenant $Config.Tenant -DryRun $true } | Should Not Throw
            Assert-MockCalled Write-Output -Times 2 -Scope It -ParameterFilter { $InputObject -match "-> Processing app registration" }
        }

    }

}
