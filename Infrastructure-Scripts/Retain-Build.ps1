<#
    .SYNOPSIS
    Retains a build in Azure DevOps by setting a retention lease.

    .DESCRIPTION
    This script sends a request to the Azure DevOps REST API to retain a build.
    Retaining a build prevents it from being deleted by automatic retention policies.
    It requires authentication via `System.AccessToken`, which must be passed as a parameter.

    .PARAMETER DefinitionId
    The ID of the build pipeline definition.

    .PARAMETER RunId
    The ID of the build run to be retained.

    .PARAMETER OwnerId
    The owner of the retention lease, typically the user who triggered the build.

    .PARAMETER CollectionUri
    The URI of the Azure DevOps collection.

    .PARAMETER TeamProject
    The name of the Azure DevOps team project.

    .PARAMETER AccessToken
    The system access token required for authentication to the Azure DevOps REST API.

    .EXAMPLE
    # Example usage
    .\Retain-Build.ps1 -DefinitionId 3223 -RunId 896262 -OwnerId "User:ea697f47-8ede-489e-a18c-afb8f4ba1495" -CollectionUri "https://dev.azure.com/sfa-gov-uk/" -TeamProject "Digital Apprenticeship Service" -AccessToken "xyz123"

    This command retains a build with ID 896262 in the Azure DevOps project "Digital Apprenticeship Service".
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$DefinitionId,

    [Parameter(Mandatory = $true)]
    [String]$RunId,

    [Parameter(Mandatory = $true)]
    [String]$OwnerId,

    [Parameter(Mandatory = $true)]
    [String]$CollectionUri,

    [Parameter(Mandatory = $true)]
    [String]$TeamProject,

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [String]$AccessToken
)

if (-not $AccessToken -or $AccessToken -eq "") {
    throw "ERROR: AccessToken is missing!"
}


Write-Output "AccessToken received successfully."

# Build API Request
$contentType = "application/json"
$headers = @{ Authorization = "Bearer $AccessToken" }
$rawRequest = @{
    daysValid = 365
    definitionId = $DefinitionId
    ownerId = $OwnerId
    protectPipeline = $false
    runId = $RunId
}
$request = ConvertTo-Json @($rawRequest)
$uri = "$CollectionUri$TeamProject/_apis/build/retention/leases?api-version=6.0-preview.1"

Write-Output "Sending retention request to Azure DevOps API..."
Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -ContentType $contentType -Body $request
Write-Output "Retention request sent successfully!"
