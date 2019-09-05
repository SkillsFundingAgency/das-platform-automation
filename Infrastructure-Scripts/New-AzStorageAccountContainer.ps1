<#
    .SYNOPSIS
    Create an ARM Storage Container.

    .DESCRIPTION
    Create one or more containers in a storage account.

    .PARAMETER Location
    The location of the Resource Group. This is limited to West Europe and North Europe.

    .PARAMETER Name
    The name of the Storage Account.

    .PARAMETER ContainerName
    The names of one or more Containers to create in the Storage Account.

    .PARAMETER ContainerPermission
    The permission on the Container(s). The acceptable values are 'Container', 'Blob' or 'Off'

    .EXAMPLE
    .\New-AzStorageAccountContainer.ps1 -Location "West Europe" -Name stracc -ContainerName public -ContainerPermission "Blob"

    .EXAMPLE
    .\New-AzStorageAccountContainer.ps1 -Location "West Europe" -Name stracc -ContainerName public,private,images -ContainerPermission "Blob"
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("West Europe", "North Europe")]
    [String]$Location = $ENV:Location,
    [Parameter(Mandatory = $true)]
    [String]$Name,
    [Parameter(Mandatory = $true)]
    [String[]]$ContainerName,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Container", "Blob", "Off")]
    [String]$ContainerPermission = "Off"
)

try {
    # --- Check if the storage account exists
    $StorageAccountResource = Get-AzResource -Name $Name -ResourceType "Microsoft.Storage/storageAccounts"

    if (!$StorageAccountResource) {
        throw "Could not find storage account $Name"
    }

    $StorageAccount = Get-AzStorageAccount -ResourceGroupName $StorageAccountResource.ResourceGroupName -Name $Name
    $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResource.ResourceGroupName -Name $Name)[0].Value
    $StorageAccountContext = New-AzStorageContext -StorageAccountName $Name -StorageAccountKey $StorageAccountKey

    # --- Create containers in the storage account if required
    if ($ContainerName -and $StorageAccount) {
        foreach ($Container in $ContainerName) {
            $ContainerExists = Get-AzStorageContainer -Context $StorageAccountContext -Name $Container -ErrorAction SilentlyContinue
            if (!$ContainerExists) {
                try {
                    $null = New-AzStorageContainer -Context $StorageAccountContext -Name $Container -Permission $ContainerPermission
                }
                catch {
                    throw "Could not create container $Container : $_"
                }
            }
        }
    }

    # --- If the storage account exists in this subscription get the key and set the env variable
    if ($StorageAccount) {
        $ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($Name);AccountKey=$($StorageAccountKey)"
        Write-Output ("##vso[task.setvariable variable=StorageConnectionString; issecret=true;]$($ConnectionString)")
    }
}
catch {
    throw $_
}
