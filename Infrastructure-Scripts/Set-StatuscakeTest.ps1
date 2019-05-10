[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$StatuscakeUsername,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$StatuscakeAPIKey,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$TestName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$TestUrl
)

try {
    function Invoke-StatuscakeMethod {
        param(
            $Uri,
            $Method = "GET",
            $Body = $null
        )
        Invoke-RestMethod -Uri $Uri -Method $Method -ContentType "application/x-www-form-urlencoded" -Body $Body -Headers @{
            API      = $StatuscakeAPIKey
            Username = $StatuscakeUsername
        }
    }

    $TestUri = [Uri]::new($TestUrl)


    # Default config for all tests
    $TestConfig = @{
        WebsiteName    = $TestName
        WebsiteURL     = $TestUrl
        CheckRate      = 60
        TestType       = "HTTP"
        WebsiteHost    = "Azure"
        ContactGroup   = 124901 # DAS Alerts - Slack (Integration)
        TriggerRate    = 0
        TestTags       = "DAS"
        EnableSSLAlert = 1
        FollowRedirect = 1
        # Standard status codes minus 403
        StatusCodes    = "204,205,206,303,400,401,404,405,406,408,410,413,444,429,494,495,496,499,500,501,502,503,504,505,506,507,508,509,510,511,521,522,523,524,520,598,599"
    }

    $PublicReportingId = "dDpEXXOrMy"

    # Check for existing test
    $Tests = Invoke-StatuscakeMethod -Uri "https://app.statuscake.com/API/Tests?tags=$TestTags"

    $ExistingTests = @($Tests | Where-Object {
            ([Uri]$_.WebsiteURL).AbsoluteUri.TrimEnd('/') -eq $TestUri.AbsoluteUri.TrimEnd('/') `
                -or $_.WebsiteName.ToLower() -eq $TestName.ToLower()
        })

    if ($ExistingTests.Count -gt 1) {
        throw "Multiple existing tests found matching '$TestName' or '$TestUrl'"
    }
    elseif ($ExistingTests.Count -eq 1) {
        $TestConfig.Add("TestID", "$($ExistingTests[0].TestID)")
    }

    # Create or update
    $QueryString = [string]::Join('&', ($TestConfig.GetEnumerator() | ForEach-Object { return "$($_.Key)=$($_.Value)" }))

    $Response = Invoke-StatuscakeMethod -Uri "https://app.statuscake.com/API/Tests/Update" -Method "PUT" -Body $QueryString

    Write-Output "$($Response.Message)"
}
catch {
    throw "$_"
}
