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
    daysValid = 365 * 2
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
