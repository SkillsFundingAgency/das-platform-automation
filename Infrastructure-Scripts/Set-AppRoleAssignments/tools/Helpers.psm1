class AppRoleAssignment {
    [string[]]$allowedMemberTypes = @("User", "Application")
    [string]$description = ""
    [string]$displayName = ""
    [bool]$isEnabled = $true
    [string]$value = ""
}

function Get-Environment {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ResourceName
    )

    $ValidEnvironments = @("at", "test", "test2", "demo", "pp", "prd", "mo")
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

function Set-AzureCLIAccess {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$IdentifierUri,
        [Parameter(Mandatory = $true)]
        [String]$ServicePrincipalObjectId
    )

    #Authorize Azure CLI to call app registration and acquire a token
    #https://docs.microsoft.com/en-us/graph/api/resources/preauthorizedapplication?view=graph-rest-1.0
    $AppRegistrationObject = (az ad app show --id $IdentifierUri | ConvertFrom-Json)
    $MicrosoftGraphRequestParameters =
    "--method", "patch",
    "--uri", "https://graph.microsoft.com/v1.0/applications/$($AppRegistrationObject.objectId)",
    "--headers", "Content-Type=application/json",
    "--body", "{api:{preAuthorizedApplications:[{appId:'04b07795-8ddb-461a-bbee-02f9e1bf7b46',delegatedPermissionIds:['$($AppRegistrationObject.oauth2Permissions.id)']}]}}"
    
    az rest @MicrosoftGraphRequestParameters
    
    #Apply User Assignment required so only authorized users can acquire a token
    #https://docs.microsoft.com/en-us/graph/api/serviceprincipal-update?view=graph-rest-1.0&tabs=http
    $MicrosoftGraphRequestParameters =
    "--method", "patch",
    "--uri", "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalObjectId",
    "--headers", "Content-Type=application/json",
    "--body", "{appRoleAssignmentRequired : true}"
    az rest @MicrosoftGraphRequestParameters
}

function New-AppRegistrationAppRole {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$AppRoleName,
        [Parameter(Mandatory = $true)]
        [String]$IdentifierUri,
        [Parameter(Mandatory = $true)]
        [String]$Environment
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

    #https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignedto?view=graph-rest-1.0&tabs=http
    $MicrosoftGraphRequestParameters =
    "--method", "get",
    "--uri", "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalId/appRoleAssignedTo"

    $AppRoleAssignments = az rest @MicrosoftGraphRequestParameters | ConvertFrom-Json
    return $AppRoleAssignments
}

function New-AppRoleAssignment {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ServicePrincipalId,
        [Parameter(Mandatory = $true)]
        [String]$AppRoleId,
        [Parameter(Mandatory = $true)]
        [String]$ManagedIdentity,
        [Parameter(Mandatory = $true)]
        [ValidateSet("ServicePrincipal", "Group")]
        [String]$PrincipalType
    )

    #https://docs.microsoft.com/en-us/graph/api/serviceprincipal-post-approleassignedto?view=graph-rest-1.0&tabs=http
    $MicrosoftGraphRequestParameters =
    "--method", "post",
    "--uri", "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalId/appRoleAssignedTo",
    "--body", "{'appRoleId': '$AppRoleId', 'principalId': '$ManagedIdentity', 'resourceId': '$ServicePrincipalId', 'principalType': '$PrincipalType'}"

    az rest @MicrosoftGraphRequestParameters --output none 2>$null
}
