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

    .PARAMETER SandboxEnabled
    (optional) The boolean for creating a sandbox API version set and its sandbox APIs for sandbox equivalent of provided ProductId. Defaults to false

    .PARAMETER ImportRetries
    (optional) The number of times to retry importing the API definition, defaults to 3

    .PARAMETER AddXForwardedAuthorization
    (optional) The boolean for adding a new header called X-Forwarded-Authorization that is set to be the original inbound Authorization value

    .PARAMETER CheckClientCert
    (optional) The boolean to add a policy which checks the client certificate used to authenticate requests, requests can still be sent via non-secure gateway and client cert not checked

    .PARAMETER MandateCheckClientCert
    (optional) The boolean to add a policy which mandates the client certificate used to authenticate request via the secure-gateway.

    .PARAMETER ApimKeyVaultUri
    (optional) The keyvault client certificate uri

    .PARAMETER ApimKeyVaultClientCertName
    (optional) The keyvault client certificate uri

    .EXAMPLE
    Import-ApimSwaggerApiDefinition -ApimResourceGroup das-at-foobar-rg -InstanceName das-at-foobar-apim -AppServiceResourceGroup das-at-foobar-rg -ApiVersionSetName foobar-api -ApiBaseUrl "https://at-foobar-api.apprenticeships.education.gov.uk" -ApiPath "foo-bar" -ApplicationIdentifierUri "https://<tenant>.onmicrosoft.com/das-at-foobar-as-ar" -ProductId ProductId
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "Known bug - https://github.com/PowerShell/PSScriptAnalyzer/issues/1472")]
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
    [String]$ProductId,
    [Parameter(Mandatory = $false)]
    [bool]$SandboxEnabled = $false,
    [Parameter(Mandatory = $false)]
    [int]$ImportRetries = 3,
    [Parameter(Mandatory = $false)]
    [bool]$AddXForwardedAuthorization = $false,
    [Parameter(Mandatory = $false)]
    [bool]$CheckClientCert = $false,
    [Parameter(Mandatory = $false)]
    [bool]$MandateCheckClientCert = $false,
    [Parameter(Mandatory = $false)]
    [string]$ApimKeyVaultUri,
    [Parameter(Mandatory = $false)]
    [string]$ApimKeyVaultClientCertName
)

function Invoke-RetryWebRequest ($ApiUrl) {
    $Response = $null
    $AttemptCounter = 1
    while (!$Response) {
        Write-Verbose "Web request attempt: $($AttemptCounter)"
        try {
            Write-Verbose "Invoking web request to $($ApiUrl)"
            $Response = Invoke-WebRequest "$($ApiUrl)"
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
    $Response
}

function Get-SwaggerFilePath ($IndexJs) {
    $Paths = @()
    $MatchedStrings = Select-String '/swagger/v\d/swagger.json' -input $IndexJs -AllMatches
    foreach ($MatchedString in $MatchedStrings) {
        $Paths += $MatchedString.matches -split ' '
    }
    Write-Verbose "Retrieved $($Paths.Count) swagger file paths"
    $Paths
}

function Get-ApiTitle ($SwaggerSpecificationUrl) {
    $ApiTitle = ((Invoke-RetryWebRequest $SwaggerSpecificationUrl).Content | ConvertFrom-Json).info.title
    $ApiTitle
}

function Save-SwaggerSpecification {
    Param(
        [String]$SwaggerSpecificationUrl,
        [string]$ApiName,
        [switch]$SandboxEnabled
    )
    $SwaggerContent = (Invoke-RetryWebRequest $SwaggerSpecificationUrl).Content
    if ($SandboxEnabled.IsPresent) {
        $ApiName += " Sandbox"
        $SwaggerContentObject = $SwaggerContent | ConvertFrom-Json -Depth 20
        $SwaggerContentObject.info.title = $ApiName
        $SwaggerContent = $SwaggerContentObject | ConvertTo-Json -Depth 20
    }
    Write-Verbose "Saving swagger specification to $($SwaggerSpecificationFilePath)"
    $SwaggerContent | Out-File -FilePath $SwaggerSpecificationFilePath
}

function Get-AppServiceName ($ApiBaseUrl, $AppServiceResourceGroup) {
    $AppServices = Get-AzWebApp -ResourceGroupName $AppServiceResourceGroup
    $Hostname = ($ApiBaseUrl -replace "https://", "").TrimEnd('/')
    $AppServiceName = ($AppServices | Where-Object { $_.hostnames -like $Hostname }).Name
    $AppServiceName
}

function Add-AppServiceWhitelist ($AppServiceResourceGroup, $AppServiceName) {
    $IpRestrictions = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $AppServiceResourceGroup -Name $AppServiceName
    Write-Verbose "Getting IP address"
    $MyIp = (Invoke-RestMethod ifconfig.me/ip -UseBasicParsing)
    if ($IpRestrictions.MainSiteAccessRestrictions.RuleName -notcontains "Allow all" -and ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).IpAddress -notcontains "$MyIp/32") {
        Write-Verbose "Whitelisting $MyIp"
        $Priority = ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).Priority[-1] + 1
        $null = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResourceGroup -WebAppName $AppServiceName -Name "DeployServer" -IpAddress "$MyIp/32" -Priority $Priority -Action Allow
    }
}

function Import-Api {
    Param(
        [Parameter(Mandatory = $true)]
        [String]$ProductId,
        [Parameter(Mandatory = $true)]
        [String]$ApiVersionSetName,
        [Parameter(Mandatory = $true)]
        [String]$SwaggerPath,
        [Parameter(Mandatory = $true)]
        [String]$ApiPath,
        [Parameter(Mandatory = $false)]
        [switch]$SandboxEnabled
    )
    $SwaggerSpecificationUrl = $ApiBaseUrl + $SwaggerPath
    $SwaggerPath -match '\d' | Out-Null
    $Version = $matches[0]
    $ApiTitle = Get-ApiTitle $SwaggerSpecificationUrl
    if ($SandboxEnabled.IsPresent) {
        $ProductId = $ProductId + "-Sandbox"
        $ApiId = $ApiTitle.replace(" ","-") + "-Sandbox-v" + $Version.ToUpper()
        $ApiVersionSetName = $ApiVersionSetName + "-Sandbox"
        $ApiPath = "sandbox/" + $ApiPath
        Save-SwaggerSpecification -SwaggerSpecificationUrl $SwaggerSpecificationUrl -ApiName $ApiTitle -SandboxEnabled
    }
    else {
        $ApiId = $ApiTitle.replace(" ","-") + "-v" + $Version.ToUpper()
        Save-SwaggerSpecification -SwaggerSpecificationUrl $SwaggerSpecificationUrl
    }

    $VersionSet = Get-AzApiManagementApiVersionSet -Context $Context | Where-Object { $_.DisplayName -eq "$ApiVersionSetName" }
    if ($null -eq $VersionSet) {
        Write-Verbose "Creating new version set $ApiVersionSetName"
        $VersionSetId = (New-AzApiManagementApiVersionSet -Context $Context -Name "$ApiVersionSetName" -Scheme "Header" -HeaderName "X-Version" -Description $ApiVersionSetName).Id
    }
    else {
        Write-Verbose "Setting VersionSetId to $($VersionSet.Id)"
        $VersionSetId = $VersionSet.Id
    }

    for ($r = 0; $r -lt $ImportRetries; $r++) {
        try {
            Write-Verbose "Importing API definition from swagger file path $SwaggerSpecificationFilePath defined at $SwaggerSpecificationUrl into ApiId $ApiId with ApiVersion $Version of ApiVersionSet $VersionSetId"
            $Result = Import-AzApiManagementApi -Context $Context -SpecificationFormat OpenApi -ServiceUrl $ApiBaseUrl -SpecificationPath $SwaggerSpecificationFilePath -Path $ApiPath -ApiId $ApiId -ApiVersion $Version -ApiVersionSetId $VersionSetId -ErrorAction Stop
        }
        catch {
            Write-Error $_
        }

        if ($Result) {
            Write-Verbose "API definition successfully imported"
            $Result
            break
        }

        Write-Warning "API definition import failed, retrying attempt $($r + 1)"
    }

    if (!$Result) {
        throw "Failed to import API definition after $ImportRetries attempts"
    }

    Remove-Item -Path $SwaggerSpecificationFilePath

    Add-AzApiManagementApiToProduct -Context $Context -ProductId $ProductId -ApiId $ApiId

    Set-AzApiManagementPolicy -Context $Context -ApiId $ApiId -Policy $PolicyString -Format "application/vnd.ms-azure-apim.policy.raw+xml"
}

$SwaggerSpecificationFilePath = "./swagger-specification.json"

if ($AddXForwardedAuthorization) {
    Write-Verbose "Setting new inbound policy to add new header X-Forwarded-Authorization"
    $XForwardedAuthorizationHeaderPolicy = '<set-header name="X-Forwarded-Authorization" exists-action="override"><value>@(context.Request.Headers.FirstOrDefault(x=>x.Key=="Authorization").Value?.FirstOrDefault())</value></set-header>'
}
if ($MandateCheckClientCert){
    Write-Verbose "Setting new inbound policy to mandate the checking of client certificate"
    $PolicyString = "<policies><inbound><set-variable name=`"ValidateThumbprint`" value=`"@{return true;}`" /> <set-variable name=`"ApplicationIdentifierUri`" value=`"$ApplicationIdentifierUri`" /> <set-variable name=`"ApimKeyVaultUri`" value=`"$ApimKeyVaultUri`" /> <set-variable name=`"ApimKeyVaultClientCertName`" value=`"$ApimKeyVaultClientCertName`" /> <include-fragment fragment-id=`"checkClientCert`"/><base/>$XForwardedAuthorizationHeaderPolicy</inbound><backend><base/></backend><outbound><base/></outbound><on-error><base/></on-error></policies>"
    Write-Output $PolicyString
}
elseif ($CheckClientCert){
    Write-Verbose "Setting new inbound policy to check for client certificate"
    $PolicyString = "<policies><inbound><set-variable name=`"ValidateThumbprint`" value=`"@{return context.Request.Headers.GetValueOrDefault(`"Host`", `"Unknown`").ToLower().Contains(`"secure-gateway.apprenticeships`");}`" /> <set-variable name=`"ApplicationIdentifierUri`" value=`"$ApplicationIdentifierUri`" /> <set-variable name=`"ApimKeyVaultUri`" value=`"$ApimKeyVaultUri`" /> <set-variable name=`"ApimKeyVaultClientCertName`" value=`"$ApimKeyVaultClientCertName`" /> <include-fragment fragment-id=`"checkClientCert`"/><base/>$XForwardedAuthorizationHeaderPolicy</inbound><backend><base/></backend><outbound><base/></outbound><on-error><base/></on-error></policies>"
    Write-Output $PolicyString
} else {
    Write-Verbose "Setting default policy"
    $PolicyString = "<policies><inbound>$CheckClientCertPolicy<base/>$XForwardedAuthorizationHeaderPolicy<authentication-managed-identity resource=`"$ApplicationIdentifierUri`"/></inbound><backend><base/></backend><outbound><base/></outbound><on-error><base/></on-error></policies>"
}

$ApimInstanceExists = Get-AzApiManagement -ResourceGroupName $ApimResourceGroup -Name $InstanceName
if (!$ApimInstanceExists) {
    throw "APIM Instance: $InstanceName does not exist in resource group: $ApimResourceGroup"
}

Write-Verbose "Building APIM context for $ApimResourceGroup\$InstanceName"
$Context = New-AzApiManagementContext -ResourceGroupName $ApimResourceGroup -ServiceName $InstanceName

$AppServiceName = Get-AppServiceName -ApiBaseUrl $ApiBaseUrl -AppServiceResourceGroup $AppServiceResourceGroup

Add-AppServiceWhitelist -AppServiceResourceGroup $AppServiceResourceGroup -AppServiceName $AppServiceName

$IndexJs = Invoke-RetryWebRequest "$($ApiBaseUrl)/index.js"
$SwaggerPaths = Get-SwaggerFilePath -IndexJs $IndexJs

Write-Verbose "Loop through each versioned Swagger definition and import to APIM"
foreach ($SwaggerPath in $SwaggerPaths) {
    Import-Api -ProductId $ProductId -ApiVersionSetName $ApiVersionSetName -SwaggerPath $SwaggerPath -ApiPath $ApiPath
    if ($SandboxEnabled) {
        Import-Api -ProductId $ProductId -ApiVersionSetName $ApiVersionSetName -SwaggerPath $SwaggerPath -ApiPath $ApiPath -SandboxEnabled
    }
}

Write-Verbose "Removing whitelisted IP"
Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResourceGroup -WebAppName $AppServiceName -Name "DeployServer"
