<#
    .SYNOPSIS
    Grants app role assignments to the app registrations of the given Azure resources using managed identities

    .DESCRIPTION
    Grants app role assignments to the app registrations of the given Azure resources using managed identities
    Configuration of app registrations and their app roles which have resources' managed identities granted access to is stored in the configuration file passed in

    .PARAMETER AppRegistrationConfigurationFilePath
    File path of the app registration configuration file

    .PARAMETER ResourceName
    The name of the App Service to grant access to its relevant app registrations' roles.

    .PARAMETER Tenant
    Azure Tenant the app service lives in

    .PARAMETER DryRun
    Writes an output of the changes that would be made with no actual execution.

    .EXAMPLE
    .\Set-AppRoleAssignments.ps1 -AppRegistrationConfigurationFilePath "C:\config.json" -ResourceName das-env-foobar-as -Tenant tenant.onmicrosoft.com -DryRun $true
    .\Set-AppRoleAssignments.ps1 -AppRegistrationConfigurationFilePath "C:\config.json" -ResourceName das-env-foobar-apim -Tenant tenant.onmicrosoft.com -DryRun $true
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$AppRegistrationConfigurationFilePath,
    [Parameter(Mandatory = $true)]
    [String]$ResourceName,
    [Parameter(Mandatory = $true)]
    [String]$Tenant,
    [Parameter(Mandatory = $false)]
    [bool]$DryRun = $true
)

$ErrorActionPreference = "Stop"
Import-Module "$PSScriptRoot\tools\Helpers.psm1" -Force

If ($DryRun) {
    Write-Warning "Processing Dry Run"
}

try {
    $AppRegistrationConfiguration = Get-Content -Path $AppRegistrationConfigurationFilePath -Raw | ConvertFrom-Json
    $Environment = Get-Environment -ResourceName $ResourceName
    $ResourceNamePrefix = "das-$Environment"
    $ResourceNameSuffix = $ResourceName.Replace($ResourceNamePrefix, "")
    $AppRegistrationsToProcess = $AppRegistrationConfiguration.configuration | Where-Object { $_.appRegistrationSuffix -match $ResourceNameSuffix -or $_.appRoles.resourceNameSuffix -match $ResourceNameSuffix }

    if (!$AppRegistrationsToProcess) {
        throw "No app registrations to process for app service name $ResourceName. Check app service name or update configuration."
    }

    foreach ($AppRegistration in $AppRegistrationsToProcess) {
        $AppRegistrationName = "$ResourceNamePrefix$($AppRegistration.appRegistrationSuffix)"
        $IdentifierUri = "https://$Tenant/$AppRegistrationName"
        $ServicePrincipal = Get-ServicePrincipal -DisplayName $AppRegistrationName

        if ($ServicePrincipal.Count -eq 1) {
            Write-Output "-> Processing app registration $AppRegistrationName"
        }
        elseif ($ServicePrincipal.Count -gt 1) {
            Write-Error "-> Found duplicate app registrations with the same display name of $AppRegistrationName. Investigate"
        }
        else {
            Write-Output "-> App registration $AppRegistrationName not found in AAD - Creating"

            if (!$DryRun) {
                New-AppRegistration -AppRegistrationName $AppRegistrationName -IdentifierUri $IdentifierUri
            }

            Write-Output "  -> Successfully created app registration - $AppRegistrationName"
            $ServicePrincipal = Get-ServicePrincipal -DisplayName $AppRegistrationName
        }

        foreach ($AppRole in $AppRegistration.appRoles) {
            $MatchedAppRole = $ServicePrincipal.appRoles | Where-Object { $_.value -eq $AppRole.appRoleName }

            if ($MatchedAppRole) {
                Write-Output "  -> Processing app role $($AppRole.appRoleName)"
            }
            else {
                Write-Output "  -> App role $($AppRole.appRoleName) not found on app registration - Creating App Role"

                if (!$DryRun) {
                    New-AppRegistrationAppRole -AppRoleName $AppRole.appRoleName -IdentifierUri $IdentifierUri
                }

                Write-Output "    -> Successfully added app role $($AppRole.appRoleName)"

                $ServicePrincipal = Get-ServicePrincipal -DisplayName $AppRegistrationName
                $MatchedAppRole = $ServicePrincipal.appRoles | Where-Object { $_.value -eq $AppRole.appRoleName }
            }

            foreach ($MIResource in $AppRole.resourceNameSuffix) {
                $ManagedIdentityResourceName = "$ResourceNamePrefix$MIResource"
                $ManagedIdentity = Get-ServicePrincipal -DisplayName $ManagedIdentityResourceName
                if ($ManagedIdentity.Count -eq 1) {
                    Write-Output "    -> Processing Managed Identity of $ManagedIdentityResourceName"
                }
                elseif ($ManagedIdentity.Count -gt 1) {
                    Write-Error "    -> Found duplicate app registrations with the same display name of $ManagedIdentityResourceName. Investigate"
                    continue
                }
                else {
                    Write-Output "    -> Managed Identity of $ManagedIdentityResourceName not found"
                    continue
                }

                try {
                    if ($ServicePrincipal.ObjectId) {
                        $AppRoleAssignments = Get-AppRoleAssignments -ServicePrincipalId $ServicePrincipal.ObjectId
                        $AppRoleAssignmentExists = $AppRoleAssignments.value | Where-Object { $_.appRoleId -eq $MatchedAppRole.id -and $_.principalId -eq $ManagedIdentity.ObjectId }

                        if ($AppRoleAssignmentExists) {
                            Write-Output "      -> App role assignment already exists"
                            continue
                        }
                        else {
                            Write-Output "      -> Processing new app role assignment for $ManagedIdentityResourceName with role: $($MatchedAppRole.value)"

                            if (!$DryRun) {
                                New-AppRoleAssignment -ServicePrincipalId $ServicePrincipal.ObjectId -AppRoleId $MatchedAppRole.id -ManagedIdentity $ManagedIdentity.ObjectId
                            }

                            Write-Output "      -> Successfully created app role assignment"
                        }
                    }
                }
                catch {
                    Write-Error "        -> Error: $_"
                }
            }
        }
    }
}
catch {
    throw "$_"
}
