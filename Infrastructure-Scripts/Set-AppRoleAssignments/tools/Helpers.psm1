class AppRoleAssignment {
    [string[]]$allowedMemberTypes = @("Application")
    [string]$description = ""
    [string]$displayName = ""
    [bool]$isEnabled = $true
    [string]$origin = "Application"
    [string]$value = ""
}

function Get-Environment {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ResourceName
    )

    $ValidEnvironments = @("at", "test", "test2", "demo", "pp", "prd", "mo", "poc")
    $Environment = $ResourceName.Split('-')[1]

    if ($Environment -in $ValidEnvironments) {
        return $Environment
    }
    else {
        throw "Environment retrieved from app service name not valid"
    }
}

function Get-ServicePrincipal {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$DisplayName
    )

    $ServicePrincipal = az ad sp list --filter "displayName eq '$DisplayName'" | ConvertFrom-Json
    return $ServicePrincipal
}

function New-AppRegistration {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$AppRegistrationName,
        [Parameter(Mandatory = $true)]
        [String]$IdentifierUri
    )

    az ad app create --display-name $AppRegistrationName --identifier-uris $IdentifierUri --output none 2>$null
    az ad sp create --id $IdentifierUri --output none 2>$null
}

function New-AppRegistrationAppRole {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$AppRoleName,
        [Parameter(Mandatory = $true)]
        [String]$IdentifierUri
    )

    $Manifest = [System.Collections.ArrayList]::new()
    $ExistingAppRoles = az ad app show --id $IdentifierUri --query="appRoles" | ConvertFrom-Json
    foreach ($ExistingAppRole in $ExistingAppRoles) {
        $null = $Manifest.Add($ExistingAppRole)
    }

    $Template = [AppRoleAssignment]::new()
    $Template.description = $AppRoleName
    $Template.displayName = $AppRoleName
    $Template.value = $AppRoleName
    $null = $Manifest.Add($Template)

    $ManifestFilePath = "$PSScriptRoot\manifest.json"
    ConvertTo-Json $Manifest -Depth 100 | Set-Content -Path $ManifestFilePath
    az ad app update --id $IdentifierUri --app-roles $ManifestFilePath
    Remove-Item -Path $ManifestFilePath
}

function Get-AppRoleAssignments {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ServicePrincipalId
    )

    $AppRoleRegistrationRequestParameters =
    "--method", "get",
    "--uri", "https://graph.microsoft.com/beta/servicePrincipals/$ServicePrincipalId/appRoleAssignedTo"

    $AppRoleAssignments = az rest @AppRoleRegistrationRequestParameters | ConvertFrom-Json
    return $AppRoleAssignments
}

function New-AppRoleAssignment {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ServicePrincipalId,
        [Parameter(Mandatory = $true)]
        [String]$AppRoleId,
        [Parameter(Mandatory = $true)]
        [String]$ManagedIdentity
    )

    $AppRoleRegistrationRequestParameters =
    "--method", "post",
    "--uri", "https://graph.microsoft.com/beta/servicePrincipals/$ServicePrincipalId/appRoleAssignedTo",
    "--body", "{'appRoleId': '$AppRoleId', 'principalId': '$ManagedIdentity', 'resourceId': '$ServicePrincipalId', 'principalType': 'ServicePrincipal'}"

    az rest @AppRoleRegistrationRequestParameters --output none 2>$null
}
