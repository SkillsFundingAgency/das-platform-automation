<#
    .SYNOPSIS
    Imports the results of the OWASP Dependency Check build task to a Log Analytics workspace as custom logs.
    .DESCRIPTION
    Imports the results of the OWASP Dependency Check build task to a Log Analytics workspace as custom logs.
    .PARAMETER CustomerId
    The workspace ID of the Log Analytics workspace.
    .PARAMETER SharedKey
    The Primary/Secondary key of the Log Analytics workspace.
    .EXAMPLE
    .\Import-OwaspDependencyCheckResults.ps1 -CustomerId $(ProdLogAnalyticsWorkspaceId) -SharedKey $(ProdLogAnalyticsWorkspaceKey)
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$CustomerId,
    [Parameter(Mandatory = $true)]
    [string]$SharedKey
)
try {

    # Specify the name of the record type that you'll be creating
    $LogType = "OwaspDependencyCheck"

    # You can use an optional field to specify the timestamp from the data. If the time field is not specified, Azure Monitor assumes the time is the message ingestion time
    $TimeStampField = Get-Date -Format "o"

    # Convert dependency scan csv to json, adding properties of build
    $json = Import-Csv "$ENV:AGENT_BUILDDIRECTORY/TestResults/dependency-check/dependency-check-report.csv"`
    | ForEach-Object { $_`
        | Add-Member -NotePropertyMembers (@{
                RepositoryName = $ENV:BUILD_REPOSITORY_NAME.split("/")[1]
                BranchName     = $ENV:BUILD_SOURCEBRANCHNAME
                BuildNumber    = $ENV:BUILD_BUILDNUMBER
                CommitId       = $ENV:BUILD_SOURCEVERSION
            }) -PassThru }`
    | ConvertTo-Json

    # Create the function to create the authorization signature
    Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
        $xHeaders = "x-ms-date:" + $date
        $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)

        $sha256 = New-Object System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
        $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
        return $authorization
    }


    # Create the function to create and post the request
    Function Send-LogAnalyticsData($customerId, $sharedKey, $body, $logType) {
        $method = "POST"
        $contentType = "application/json"
        $resource = "/api/logs"
        $rfc1123date = [DateTime]::UtcNow.ToString("r")
        $contentLength = $body.Length
        $signature = Build-Signature `
            -customerId $customerId `
            -sharedKey $sharedKey `
            -date $rfc1123date `
            -contentLength $contentLength `
            -method $method `
            -contentType $contentType `
            -resource $resource
        $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

        $headers = @{
            "Authorization"        = $signature;
            "Log-Type"             = $logType;
            "x-ms-date"            = $rfc1123date;
            "time-generated-field" = $TimeStampField;
        }

        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
        return $response.StatusCode

    }

    # Submit the data to the API endpoint
    Send-LogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType
}
catch {
    throw "$_"
}
