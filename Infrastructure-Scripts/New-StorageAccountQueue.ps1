<#
    .SYNOPSIS
    Creates an Azure Storage Queue in a Storage Account if there is not one with the supplied Name.

    .DESCRIPTION
    Creates an Azure Storage Queue in a Storage Account if there is not one with the supplied Name.

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER QueueName
    The name of the table to be created.

    .EXAMPLE
    .\New-StorageAccountQueue.ps1 -ResourceGroup rgname -StorageAccount saname -QueueName tablename

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
    [String]$QueueName
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
    $QueueExists = Get-AzStorageQueue -Name $QueueName -Context $ctx  -ErrorAction SilentlyContinue
    if (!$QueueExists) {
        try {
            $result = New-AzStorageQueue -Name $QueueName -Context $ctx
            Write-Output $result
        }
        catch {
            throw "Could not create Table $QueueName : $_"
        }
    }
}

catch {
    throw "$_"
}
