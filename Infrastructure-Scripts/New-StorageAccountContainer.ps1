<#
    .SYNOPSIS
    Creates an Azure Storage Queue or Table Container in a Storage Account if there is not one with the supplied Name and Type.

    .DESCRIPTION
    Creates an Azure Storage Queue or Table Container in a Storage Account if there is not one with the supplied Name and Type.

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER ContainerType
    The Name of the table to be create will only accept table and queue.

    .PARAMETER ContainerName
    The Name of the table to be create.

    .EXAMPLE
    .\New-StorageAccountContainer.ps1 -ResourceGroup rgname -StorageAccount saname -ContainerType container type -ContainerName tablename

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
    [ValidateSet("table","queue")]
    [String]$ContainerType,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ContainerName
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
    # --- Get Key for Storage account and set up context.
    $Key = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount)[0].Value
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $key

    if ($ContainerType -eq "queue") {
        # --- Create Table Storage Queue .
        $QueueExists = Get-AzStorageQueue -Name $ContainerName -Context $ctx  -ErrorAction SilentlyContinue
        if (!$QueueExists) {
            try {
                $result = New-AzStorageQueue -Name $ContainerName -Context $ctx
                Write-Output $result
            }
            catch {
                throw "Could not create Table $ContainerName : $_"
            }
        }
    }

    if ($ContainerType -eq "table") {
        # --- Create Table Storage Table .
        $TableExists = Get-AzStorageTable -Name $ContainerName -Context $ctx  -ErrorAction SilentlyContinue
        if (!$TableExists) {
            try {
                $result = New-AzStorageTable -Name $ContainerName -Context $ctx
                Write-Output $result
            }
            catch {
                throw "Could not create Table $ContainerName : $_"
            }
        }
    }
}
catch {
    throw "$_"
}
