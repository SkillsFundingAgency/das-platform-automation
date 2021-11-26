<#
    .SYNOPSIS
    Dynamically gets the current IP address from "https://ifconfig.me/ip"

    .DESCRIPTION
    Dynamically gets the current IP address from "https://ifconfig.me/ip"

    .PARAMETER WhatsMyIpUrl
    The url value, e.g. "https://ifconfig.me/ip" that is called to identify the IP Address of the machine running the script

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
$MyIPAddress = (Invoke-RestMethod -Uri $WhatsMyIpUrl -UseBasicParsing)
$IpRegEx = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"

#Check if IP Address matches $IpRegex
if ($MyIPAddress -notmatch $IpRegEx) {
    throw "Invalid $MyIPAddress"
}
#Set the variables
else {
    Write-Output "Setting value of MyIPAddress value to IP Address "
    Write-Output "##vso[task.setvariable variable=IPAddress]$MyIPAddress"
    return $MyIPAddress
}
