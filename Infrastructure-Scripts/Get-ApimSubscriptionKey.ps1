<#
    .SYNOPSIS
    Gets an APIM subscription primary key for a given product and outputs the value as a Azure DevOps pipeline variable. 
    Creates a subscription key if it does not exist in the given product

    .DESCRIPTION
    Gets an APIM subscription primary key for a given product and outputs the value as a Azure DevOps pipeline variable. 
    Creates a subscription key if it does not exist in the given product.

    .PARAMETER ApimResourceGroup
    The name of the resource group the APIM instance is deployed in

    .PARAMETER ApimName
    The name of the APIM instance

    .PARAMETER Product
    The name of the APIM product

    .PARAMETER SubscriptionName
    The display name of the subscription to search for/create.

    .PARAMETER PipelineVariableName
    The pipeline variable name that will store the subscription key

    .EXAMPLE
    .\Set-ApimSubscriptionkey.ps1 -ApimResourceGroup das-foo-bar-rg -ApimName das-foo-bar-apim -Product FooBarProduct -SubscriptionName Foobar -PipelineVariableName FooBar
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
$ApimSubscriptionKey = (Get-AzApiManagementSubscriptionKey -Context $Context -SubscriptionId $SubscriptionId).PrimaryKey

Write-Output "##vso[task.setvariable variable=$PipelineVariableName;issecret=true]$ApimSubscriptionKey"