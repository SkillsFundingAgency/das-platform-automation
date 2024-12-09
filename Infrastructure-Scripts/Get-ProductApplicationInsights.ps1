<#
    .SYNOPSIS
    Gets and outputs the connection string and resource id of the services application insights.

    .DESCRIPTION
    Gets and outputs the connection string and resource id of the services application insights.

    .PARAMETER AppInsightsResourceGroup
    The name of the resource group the application insights is deployed to

    .PARAMETER AppInsightsName
    The name of the product application insights

    .EXAMPLE
    .\Get-ProductApplicationInsights.ps1 -ResourceGroupName das-foo-bar-rg -Name das-foo-shared-bar-ai
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$AppInsightsResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$AppInsightsName
)

$applicationInsights = Get-AzApplicationInsights -ResourceGroupName $AppInsightsResourceGroup -Name $AppInsightsName

if ($applicationInsights) {
    $applicationInsightsResourceId = $applicationInsights.Id
    $applicationInsightsConnectionString = $applicationInsights.Connectionstring
}
else {
    throw "Application Insights $applicationInsights not found"
}


Write-Output "Setting value of application insights respirce Id to pipeline variable"
Write-Output "##vso[task.setvariable variable=applicationInsightsResourceId]$applicationInsightsResourceId"

Write-Output "Setting value of application insights connection string to secret pipeline variable"
Write-Output "##vso[task.setvariable variable=applicationInsightsConnectionString;issecret=true]$applicationInsightsConnectionString"
