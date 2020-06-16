<#
    .SYNOPSIS
    Update an APIM API with a swagger definition
    .DESCRIPTION
    Update an APIM API with a swagger definition
    .PARAMETER ApimResourceGroup
    The name of the resource group that contains the APIM instnace
    .PARAMETER InstanceName
    The name of the APIM instance
    .PARAMETER ApiName
    The name of the API to update
    .PARAMETER SwaggerSpecificationUrl
    The full path to the swagger defintion
    .PARAMETER ApiPath
    (optional) The URL suffix that APIM will apply to the API URL.  If this has not been set via an ARM template then it must be passed in as a parameter
    .PARAMETER ApiSpecificationFormat
    (optional) Specify the format of the document to import, defaults to 'Swagger'.  The 'OpenApi' format is only supported when using the Az module so the UseAzModule switch must also be specified when using that format.  Setting the ApiSpecificationFormat will have no effect without this switch.
    .PARAMETER SwaggerSpecificationFile
    (optional)  Switch, specifies whether the swagger file should be saved to a local directory before importing in APIM.
    .PARAMETER OutputFilePath
    (optional)  The path to save the swagger file to if SwaggerSpecificationFile switch is used.
    .PARAMETER UseAzModule
    (optional)  Defaults to false.  Set this parameter to $true to use the Az cmdlets for zero downtime deployments.  This parameter can be removed at a later date when the AzureRm cmdlets are no longer required.
    .EXAMPLE
    Import-ApimSwaggerApiDefinition -ApimResourceGroup dfc-foo-bar-rg -InstanceName dfc-foo-bar-apim -ApiName bar -SwaggerSpecificationUrl "https://dfc-foo-bar-fa.azurewebsites.net/api/bar/api-definition" -SwaggerSpecificationFile -OutputFilePath $(System.DefaultWorkingDirectory)/SwaggerFile -Verbose
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
    [String]$ApplicationIdentifierUri
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
    $SwaggerPath -match 'v\d' | Out-Null
    $Version = $matches[0]
    $ApiId = "$ApiName-" + $Version.ToUpper()

    # Get Version Set for given ApiName or create one if it does not exist
    $VersionSet = Get-AzApiManagementApiVersionSet -Context $Context | Where-Object { $_.DisplayName -eq "$ApiName" }
    if ($null -eq $VersionSet) {
        $VersionSetId = (New-AzApiManagementApiVersionSet -Context $Context -Name "$ApiName" -Scheme "Header" -HeaderName "X-version" -Description $ApiName).Id
    }
    else {
        $versionSetId = $VersionSet.Id
    }

    # Import API to APIM with swagger json file
    Import-AzApiManagementApi -Context $Context -SpecificationFormat OpenApi -ServiceUrl $ServiceUrl -SpecificationUrl $SwaggerSpecificationUrl -Path $ApiPath -ApiId $ApiId -ApiVersion $Version -ApiVersionSetId $VersionSetId -ErrorAction Stop -Verbose:$VerbosePreference
}

# Set API Level policies
Set-AzApiManagementPolicy -Context $Context -ApiId $ApiId -Policy $PolicyString
