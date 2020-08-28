<#
    .SYNOPSIS
    Update an APIM API with a swagger definition with multiple versions
    .DESCRIPTION
    Update an APIM API with a swagger definition with multiple versions
    .PARAMETER ApimResourceGroup
    The name of the resource group that contains the APIM instance
    .PARAMETER InstanceName
    The name of the APIM instance
    .PARAMETER AppServiceResourceGroup
    The name of the resource group that contains the App Service
    .PARAMETER ApiVersionSetName
    The name of the API version set to update
    .PARAMETER ApiPath
    The URL suffix that APIM will apply to the API URL.
    .PARAMETER ApiBaseUrl
    The full path to the swagger defintion
    .PARAMETER ApplicationIdentifierUri
    The Application Identifier URI of the API app registration
    .PARAMETER ProductId
    The Id of the Product that the API will be assigned to
    .EXAMPLE
    Import-ApimSwaggerApiDefinition -ApimResourceGroup das-at-foobar-rg -InstanceName das-at-foobar-apim -AppServiceResourceGroup das-at-foobar-rg -ApiVersionSetName foobar-api -ApiBaseUrl "https://at-foobar-api.apprenticeships.education.gov.uk" -ApiPath "foo-bar" -ApplicationIdentifierUri "https://<tenant>.onmicrosoft.com/das-at-foobar-as-ar" -ProductId ProductId
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$ApimResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$InstanceName,
    [Parameter(Mandatory = $true)]
    [String]$AppServiceResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$ApiVersionSetName,
    [Parameter(Mandatory = $true)]
    [String]$ApiPath,
    [Parameter(Mandatory = $true)]
    [String]$ApiBaseUrl,
    [Parameter(Mandatory = $true)]
    [String]$ApplicationIdentifierUri,
    [Parameter(Mandatory = $true)]
    [String]$ProductId
)

function Invoke-RetryWebRequest ($ApiUrl) {
    $SuccessfulResponse = $null
    $AttemptCounter = 1
    while (!$SuccessfulResponse) {
        Write-Verbose "Web request attempt: $($AttemptCounter)"
        try {
            Write-Verbose "Invoking web request to $($ApiUrl)"
            $SuccessfulResponse = Invoke-WebRequest "$($ApiUrl)"
        }
        catch {
            if ($AttemptCounter -le 10) {
                Write-Verbose "Whitelist not in effect, retrying"
                Start-Sleep -Seconds 5
                $AttemptCounter++
            }
            else {
                throw "Could not find page at: $($ApiUrl) Error: $_"
            }
        }
    }
    $SuccessfulResponse
}

function Get-AllSwaggerFilePaths ($IndexHtml) {
    $Paths = @()
    $MatchedStrings = Select-String '/swagger/v\d/swagger.json' -input $IndexHtml -AllMatches
    foreach ($MatchedString in $MatchedStrings) {
        $Paths += $MatchedString.matches -split ' '
    }
    $Paths
}

function Get-ApiTitle ($SwaggerSpecificationUrl) {
    $ApiTitle = ((Invoke-RetryWebRequest $SwaggerSpecificationUrl).Content | ConvertFrom-Json).info.title
    $ApiTitle
}

function Get-AppServiceName ($ApiBaseUrl, $AppServiceResourceGroup) {
    $AppServices = Get-AzWebApp -ResourceGroupName $AppServiceResourceGroup
    $Hostname = ($ApiBaseUrl -replace "https://", "").TrimEnd('/')
    $AppServiceName = ($AppServices | Where-Object { $_.hostnames -like $Hostname }).Name
    $AppServiceName
}

function Add-AppServiceWhitelist ($AppServiceResourceGroup, $AppServiceName) {
    $IpRestrictions = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $AppServiceResourceGroup -Name $AppServiceName
    $MyIp = (Invoke-RestMethod ifconfig.me/ip -UseBasicParsing)
    if ($IpRestrictions.MainSiteAccessRestrictions.RuleName -notcontains "Allow all" -and ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).IpAddress -notcontains "$MyIp/32") {
        Write-Verbose "Whitelisting $MyIp"
        $Priority = ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).Priority[-1] + 1
        $null = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResourceGroup -WebAppName $AppServiceName -Name "DeployServer" -IpAddress "$MyIp/32" -Priority $Priority -Action Allow
    }
}

$PolicyString = "<policies><inbound><base/><authentication-managed-identity resource=`"$ApplicationIdentifierUri`"/></inbound><backend><base/></backend><outbound><base/></outbound><on-error><base/></on-error></policies>"

$ApimInstanceExists = Get-AzApiManagement -ResourceGroupName $ApimResourceGroup -Name $InstanceName
if (!$ApimInstanceExists) {
    throw "APIM Instance: $InstanceName does not exist in resource group: $ApimResourceGroup"
}

Write-Verbose "Building APIM context for $ApimResourceGroup\$InstanceName"
$Context = New-AzApiManagementContext -ResourceGroupName $ApimResourceGroup -ServiceName $InstanceName

$AppServiceName = Get-AppServiceName -ApiBaseUrl $ApiBaseUrl -AppServiceResourceGroup $AppServiceResourceGroup

Add-AppServiceWhitelist -AppServiceResourceGroup $AppServiceResourceGroup -AppServiceName $AppServiceName

$IndexHtml = Invoke-RetryWebRequest "$($ApiBaseUrl)/index.html"
$SwaggerPaths = Get-AllSwaggerFilePaths -IndexHtml $IndexHtml

Write-Verbose "Loop through each versioned Swagger definition and import to APIM"
foreach ($SwaggerPath in $SwaggerPaths) {
    $SwaggerSpecificationUrl = $ApiBaseUrl + $SwaggerPath
    $SwaggerPath -match '\d' | Out-Null
    $Version = $matches[0]
    $ApiTitle = Get-ApiTitle $SwaggerSpecificationUrl
    $ApiId = "$ApiTitle-v" + $Version.ToUpper()

    $VersionSet = Get-AzApiManagementApiVersionSet -Context $Context | Where-Object { $_.DisplayName -eq "$ApiVersionSetName" }
    if ($null -eq $VersionSet) {
        $VersionSetId = (New-AzApiManagementApiVersionSet -Context $Context -Name "$ApiVersionSetName" -Scheme "Header" -HeaderName "X-Version" -Description $ApiVersionSetName).Id
    }
    else {
        $versionSetId = $VersionSet.Id
    }

    Import-AzApiManagementApi -Context $Context -SpecificationFormat OpenApi -ServiceUrl $ApiBaseUrl -SpecificationUrl $SwaggerSpecificationUrl -Path $ApiPath -ApiId $ApiId -ApiVersion $Version -ApiVersionSetId $VersionSetId -ErrorAction Stop -Verbose:$VerbosePreference

    Add-AzApiManagementApiToProduct -Context $Context -ProductId $ProductId -ApiId $ApiId

    Set-AzApiManagementPolicy -Context $Context -ApiId $ApiId -Policy $PolicyString
}

Write-Verbose "Removing whitelisted IP"
Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResourceGroup -WebAppName $AppServiceName -Name "DeployServer"
