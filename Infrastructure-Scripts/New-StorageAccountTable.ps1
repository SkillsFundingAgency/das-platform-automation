<#
    .SYNOPSIS
    Return either the primary or secondary connection string for a Storage Account and write to a Azure Pipelines variable.

    .DESCRIPTION
    Return either the primary or secondary connection string for a Storage Account and write to a Azure Pipelines variable.

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER TableName
    The Name of the table to be create.
.

    .EXAMPLE
    .\New-StorageAccountTables.ps1 -ResourceGroup rgname -StorageAccount saname -TableName tablename

    Creates new Table in Table storage

.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ResourceGroup,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$StorageAccount,
    [Parameter(Mandatory = $false)]
    [string]$TableName
)

try {
    # --- Check if the Resource Group exists in the subscription.
    $ResourceGroupExists = Get-AzResourceGroup $ResourceGroup
    if (!$ResourceGroupExists) {
        throw "Resource Group $ResourceGroup does not exist."
    }

    # --- Check if Storage Account exists in the subscription.
    $StorageAccountExists = Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount -ErrorAction SilentlyContinue
    if (!$StorageAccountExists) {
        throw "Storage Account $StorageAccount does not exist."
    }

    # --- Create Table Storage.
    $ctx =  $(Get-AzStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccount).Context
    New-AzStorageTable –Name $TableName -Context $ctx
}

catch {
    throw "$_"
}
