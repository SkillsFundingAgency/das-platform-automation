<#
    .SYNOPSIS
    Creates an Azure Storage Table in a Storage Account if there is not one with the supplied Name.

    .DESCRIPTION
    Creates an Azure Storage Table in a Storage Account if there is not one with the supplied Name.

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER TableName
    The Name of the table to be create.

    .EXAMPLE
    .\New-StorageAccountTables.ps1 -ResourceGroup rgname -StorageAccount saname -TableName tablename

    Creates new Table in Table storage
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ResourceGroup,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$StorageAccount,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$TableName
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
    $Key = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount)[0].Value
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $key
    Get-AzStorageTable -Name $TableName -Context $ctx -ErrorVariable ev -ErrorAction SilentlyContinue
    if ($ev) {
        Write-Output $ev
        $result = New-AzStorageTable -Name $TableName -Context $ctx
        Write-Output ($result)
    }
    else {
        Write-Output "Storage Account $StorageAccount Already Contains a Table called $TableName"
    }
}

catch {
    throw "$_"
}
