<#
    .SYNOPSIS
    Update an APIM API with a swagger definition with multiple versions
    .DESCRIPTION
    Update an APIM API with a swagger definition with multiple versions
    .PARAMETER ApimResourceGroup
    The name of the resource group that contains the APIM instnace
    .PARAMETER InstanceName
    The name of the APIM instance
    .PARAMETER ApiName
    The name of the API to update
    .PARAMETER ApiPath
    The URL suffix that APIM will apply to the API URL.
    .PARAMETER ApiBaseUrl
    The full path to the swagger defintion
    .PARAMETER ApplicationIdentifierUri
    The Application Identifier URI of the API app registration
    .EXAMPLE
    Import-ApimSwaggerApiDefinition -ApimResourceGroup das-at-foobar-rg -InstanceName das-at-foobar-apim -ApiName foobar-api -ApiBaseUrl "https://at-foobar-api.apprenticeships.education.gov.uk" -ApiPath "foo-bar" -ApplicationIdentifierUri "https://citizenazuresfabisgov.onmicrosoft.com/das-at-foobar-as-ar"
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$ApimResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$InstanceName,
    [Parameter(Mandatory = $true)]
    [String]$ApiName,
    [Parameter(Mandatory = $true)]
    [String]$ApiPath,
    [Parameter(Mandatory = $true)]
    [String]$ApiBaseUrl,
    [Parameter(Mandatory = $true)]
    [String]$ApplicationIdentifierUri,
    [Parameter(Mandatory = $true)]
    [String]$ProductId
)


function Read-SwaggerHtml ($ApiBaseUrl) {
    Invoke-WebRequest "$ApiBaseUrl/index.html"
}

function Get-AllSwaggerFilePaths ($SwaggerHtml) {
    $Paths = @()
    Select-String '/swagger/v\d/swagger.json' -input $SwaggerHtml -AllMatches | ForEach-Object {
        $Paths = $_.matches -split ' '
    }
    $Paths
}

$PolicyString = "<policies><inbound><base/><authentication-managed-identity resource=`"$ApplicationIdentifierUri`"/></inbound><backend><base/></backend><outbound><base/></outbound><on-error><base/></on-error></policies>"

Write-Verbose "Building APIM context for $ApimResourceGroup\$InstanceName"
$Context = New-AzApiManagementContext -ResourceGroupName $ApimResourceGroup -ServiceName $InstanceName

# Get all version paths
$SwaggerHtml = Read-SwaggerHtml -ApiBaseUrl $ApiBaseUrl
$SwaggerPaths = Get-AllSwaggerFilePaths -swaggerHtml $SwaggerHtml

#Loop through each version
foreach ($SwaggerPath in $SwaggerPaths) {
    $SwaggerSpecificationUrl = $ApiBaseUrl + $SwaggerPath
    $SwaggerPath -match '\d' | Out-Null
    $Version = $matches[0]
    $ApiId = "$ApiName-v" + $Version.ToUpper()

    # Get Version Set for given ApiName or create one if it does not exist
    $VersionSet = Get-AzApiManagementApiVersionSet -Context $Context | Where-Object { $_.DisplayName -eq "$ApiName" }
    if ($null -eq $VersionSet) {
        $VersionSetId = (New-AzApiManagementApiVersionSet -Context $Context -Name "$ApiName" -Scheme "Header" -HeaderName "X-Version" -Description $ApiName).Id
    }
    else {
        $versionSetId = $VersionSet.Id
    }

    # Import API to APIM with swagger json file
    Import-AzApiManagementApi -Context $Context -SpecificationFormat OpenApi -ServiceUrl $ApiBaseUrl -SpecificationUrl $SwaggerSpecificationUrl -Path $ApiPath -ApiId $ApiId -ApiVersion $Version -ApiVersionSetId $VersionSetId -ErrorAction Stop -Verbose:$VerbosePreference

    # Add API to Product
    Add-AzApiManagementApiToProduct -Context $Context -ProductId $ProductId -ApiId $ApiId

    # Set API Level policies
    Set-AzApiManagementPolicy -Context $Context -ApiId $ApiId -Policy $PolicyString
}
