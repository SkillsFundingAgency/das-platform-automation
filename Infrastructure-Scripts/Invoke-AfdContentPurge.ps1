<#
    .SYNOPSIS
    Purges the content from Azure Front Door (AFD)

    .DESCRIPTION
    Purges the content from Azure Front Door (AFD)

    .PARAMETER AFDProfileResourceGroup
    The Resource Group of the AFD

    .PARAMETER AFDProfileName
    The AFD Profile Name

    .PARAMETER AFDEndPointName
    The AFD EndPoint Name

    .PARAMETER PurgeContent
    The assest you wish to purge from the edge nodes
    Single URL Purge: Purge individual asset by specifying the full URL, e.g., "/pictures/image1.png" or "/pictures/image1"
    Wildcard purge: Purge all folders, sub-folders, and files under an endpoint with "/*"  e.g. "/* " or "/pictures/*"
    Root domain purge: Purge the root of the endpoint with "/" in the path

    .EXAMPLE
    Invoke-AfdContentPurge.ps1 -AFDProfileResourceGroup aResourceGroup -AFDProfileName aAfdProfile -AFDEndPointName aAfdEndpoint -PurgeContent "/*"
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$AFDProfileResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$AFDProfileName,
    [Parameter(Mandatory = $true)]
    [String]$AFDEndPointName,
    [Parameter(Mandatory = $true)]
    [String]$PurgeContent
)
try {
    if ( $PurgeContent.Trim() -eq "" ) {
        throw "Purge Content blank will not run purge"
    }
    # --- Set AFD EndPoint
    $AFDEndpoint = Get-AzFrontDoorCdnEndpoint -ResourceGroupName $AFDProfileResourceGroup -ProfileName $AFDProfileName -EndpointName $AFDEndpointName
    if (!$AFDEndpoint) {
        throw "AFD Endpoint does not exist"
    }
    # --- Purging AFD EndPoint
    $AFDEndpoint | Clear-AzFrontDoorCdnEndpointContent -ContentPath $PurgeContent
}
catch {
    throw "$_"
}

