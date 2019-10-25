<#
    .SYNOPSIS
    Purges the content from an Azure Content Delivery Network (CDN)

    .DESCRIPTION
    Purges the content from an Azure Content Delivery Network (CDN)

    .PARAMETER CDNProfileResourceGroup
    The Resource Group of the CDN

    .PARAMETER CDNProfileName
    The CDN Profile Name

    .PARAMETER CDNEndPointName
    The CDN EndPoint Name

    .PARAMETER PurgeContent
    The assest you wish to purge from the edge nodes
    Single URL Purge: Purge individual asset by specifying the full URL, e.g., "/pictures/image1.png" or "/pictures/image1"
    Wildcard purge: Purge all folders, sub-folders, and files under an endpoint with "/*"  e.g. "/* " or "/pictures/*"
    Root domain purge: Purge the root of the endpoint with "/" in the path

    .EXAMPLE
    Invoke-CdnContentPurge.ps1 -CDNProfileResourceGroup aResourceGroup -CDNProfileName aCdnProfile -CDNEndPointName aCdnEndpoint -PurgeContent "/*"
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$CDNProfileResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$CDNProfileName,
    [Parameter(Mandatory = $true)]
    [String]$CDNEndPointName,
    [Parameter(Mandatory = $true)]
    [String]$PurgeContent
)
try {
    if ( $PurgeContent.Trim() -eq "" ) {
        throw "Purge Content blank will not run purge"
    }
    # --- Set CDN EndPoint
    $CDNEndpoint = Get-AzCdnEndpoint -ResourceGroupName $CDNProfileResourceGroup -ProfileName $CDNProfileName -EndpointName $CDNEndpointName
    if (!$CDNEndpoint) {
        throw "CDN Endpoint does not exist"
    }
    # ---> Purging CDN EndPoint
    Unpublish-AzCdnEndpointContent  -ResourceGroupName $CDNProfileResourceGroup -ProfileName $CDNProfileName -EndpointName $CDNEndpointName -PurgeContent $PurgeContent
}
catch {
    throw "$_"
}

