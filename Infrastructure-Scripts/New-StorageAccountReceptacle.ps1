<#
    .SYNOPSIS
    Creates an Azure Storage Queue or Table Receptacle in a Storage Account if there is not one with the supplied Name and Type.

    .DESCRIPTION
    Creates an Azure Storage Queue or Table Receptacle in a Storage Account if there is not one with the supplied Name and Type.

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER ReceptacleType
    The Name of the table to be create will only accept table and queue.

    .PARAMETER ReceptacleName
    The Name of the table to be create.

    .PARAMETER ContainerPermission
    Optional Parameter for Access type to storage container.

    .EXAMPLE
    .\New-StorageAccountReceptacle.ps1 -ResourceGroup rgname -StorageAccount saname -ReceptacleType Receptacle type -ReceptacleName tablename

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
    [ValidateSet("table","queue","blob")]
    [String]$ReceptacleType,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ReceptacleName,
    [ValidateSet("Container", "Blob", "Off")]
    [String]$ContainerPermission = "Off"
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

    if ($ReceptacleType -eq "queue") {
        # --- Create Table Storage Queue .
        $QueueExists = Get-AzStorageQueue -Name $ReceptacleName -Context $ctx  -ErrorAction SilentlyContinue
        if (!$QueueExists) {
            try {
                $result = New-AzStorageQueue -Name $ReceptacleName -Context $ctx
                Write-Output $result
            }
            catch {
                throw "Could not create Table $ReceptacleName : $_"
            }
        }
    }

    if ($ReceptacleType -eq "table") {
        # --- Create Table Storage Table .
        $TableExists = Get-AzStorageTable -Name $ReceptacleName -Context $ctx  -ErrorAction SilentlyContinue
        if (!$TableExists) {
            try {
                $result = New-AzStorageTable -Name $ReceptacleName -Context $ctx
                Write-Output $result
            }
            catch {
                throw "Could not create Table $ReceptacleName : $_"
            }
        }
    }

    if ($ReceptacleType -eq "blob") {
        # --- Create  Storage container .
        $ContainerExists = Get-AzStorageContainer -Name $ReceptacleName -Context $ctx  -ErrorAction SilentlyContinue
        if (!$ContainerExists) {
            try {
                $result = New-AzStorageContainer -Name $ReceptacleName -Context $ctx -Permission $ContainerPermission
                Write-Output $result
            }
            catch {
                throw "Could not create blob container $ReceptacleName : $_"
            }
        }
    }
}
catch {
    throw "$_"
}
