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
    $Json = Import-Csv "$ENV:AGENT_BUILDDIRECTORY/TestResults/dependency-check/dependency-check-report.csv"`
    | ForEach-Object {
        $_ | Add-Member -NotePropertyMembers (@{
                RepositoryName = $ENV:BUILD_REPOSITORY_NAME.split("/")[1]
                BranchName     = $ENV:BUILD_SOURCEBRANCHNAME
                BuildNumber    = $ENV:BUILD_BUILDNUMBER
                CommitId       = $ENV:BUILD_SOURCEVERSION
            }) -PassThru } | ConvertTo-Json

    # Create the function to create the authorization signature
    function Initialize-Signature ($CustomerId, $SharedKey, $Date, $ContentLength, $Method, $ContentType, $Resource) {
        $xHeaders = "x-ms-date:" + $Date
        $StringToHash = $Method + "`n" + $ContentLength + "`n" + $ContentType + "`n" + $xHeaders + "`n" + $Resource

        $BytesToHash = [Text.Encoding]::UTF8.GetBytes($StringToHash)
        $KeyBytes = [Convert]::FromBase64String($SharedKey)

        $Sha256 = New-Object System.Security.Cryptography.HMACSHA256
        $Sha256.Key = $KeyBytes
        $CalculatedHash = $Sha256.ComputeHash($BytesToHash)
        $EncodedHash = [Convert]::ToBase64String($CalculatedHash)
        $Authorization = 'SharedKey {0}:{1}' -f $CustomerId, $EncodedHash
        return $Authorization
    }


    # Create the function to create and post the request
    function Send-LogAnalyticsData($CustomerId, $SharedKey, $Body, $LogType) {
        $Method = "POST"
        $ContentType = "application/json"
        $Resource = "/api/logs"
        $Rfc1123Date = [DateTime]::UtcNow.ToString("r")
        $ContentLength = $body.Length
        $SignatureHashArguments = @{
            customerId    = $CustomerId
            sharedKey     = $SharedKey
            date          = $Rfc1123Date
            contentLength = $ContentLength
            method        = $Method
            contentType   = $ContentType
            resource      = $Resource
        }
        $Signature = Initialize-Signature $SignatureHashArguments
        $uri = "https://" + $CustomerId + ".ods.opinsights.azure.com" + $Resource + "?api-version=2016-04-01"

        $headers = @{
            "Authorization"        = $Signature;
            "Log-Type"             = $LogType;
            "x-ms-date"            = $Rfc1123Date;
            "time-generated-field" = $TimeStampField;
        }

        $Response = Invoke-WebRequest -Uri $Uri -Method $Method -ContentType $ContentType -Headers $Headers -Body $Body -UseBasicParsing
        return $Response.StatusCode

    }

    # Submit the data to the API endpoint
    Send-LogAnalyticsData -customerId $CustomerId -sharedKey $SharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($Json)) -logType $LogType
}
catch {
    throw "$_"
}
