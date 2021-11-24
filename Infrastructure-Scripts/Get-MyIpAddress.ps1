<#
    .SYNOPSIS
    Dynamically gets the current IP address from "https://ifconfig.me/ip"

    .DESCRIPTION
    Dynamically gets the current IP address from "https://ifconfig.me/ip"

    .PARAMETER WhatsMyIpUrl
    The name of the resource group the APIM instance is deployed to

    .EXAMPLE
    .\Get-MyIpAddress.ps1 -WhatsMyIpUrl "https://ifconfig.me/ip"
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [string]$WhatsMyIpUrl
)

#Dynamically get url from "https://ifconfig.me/ip"
$IPAddress = (Invoke-RestMethod -Uri $WhatsMyIpUrl -UseBasicParsing)
$IpRegEx = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

#Check if IP Address matches $IpRegex
if ($IPAddress -notmatch $IpRegEx) {
    throw "Invalid $IPAddress"
}
else {
    return $IPAddress
}