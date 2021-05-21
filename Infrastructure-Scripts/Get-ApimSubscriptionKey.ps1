<#
    .SYNOPSIS
    Gets an APIM subscription primary key for a given product subscription id

    .DESCRIPTION
    Gets an APIM subscription primary key for a given product subscription id

    .PARAMETER ApimResourceGroup
    The name of the resource group the APIM instance is deployed to

    .PARAMETER ApimName
    The name of the APIM instance

    .PARAMETER SubscriptionId
    The subscription id of the subscription to get

    .PARAMETER PipelineVariableName
    The pipeline variable name that will store the subscription key

    .EXAMPLE
    .\Set-ApimSubscriptionkey.ps1 -ApimResourceGroup das-foo-bar-rg -ApimName das-foo-bar-apim -SubscriptionId Foobar -PipelineVariableName FooBar
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$ApimResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$ApimName,
    [Parameter(Mandatory = $true)]
    [String]$SubscriptionId,
    [Parameter(Mandatory = $true)]
    [String]$PipelineVariableName
)

$Context = New-AzApiManagementContext -ResourceGroupName $ApimResourceGroup -ServiceName $ApimName
$ApimSubscription = Get-AzApiManagementSubscriptionKey -Context $Context -SubscriptionId $SubscriptionId

if ($ApimSubscription) {
    $ApimSubscriptionKey = $ApimSubscription.PrimaryKey
}
else {
    throw "APIM subscription not found with subcription id: $SubscriptionId"
}


Write-Output "##vso[task.setvariable variable=$PipelineVariableName;issecret=true]$ApimSubscriptionKey"