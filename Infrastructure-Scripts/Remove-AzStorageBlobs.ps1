<#
.SYNOPSIS
Deleted blobs from specified storage container

.DESCRIPTION
This script will remove all files from the specified container. It will be able to be used in an Azure DevOps release pipeline.

.PARAMETER StorageAccount
This is the name of the storage account which will contain the storage container

.PARAMETER StorageAccountKey
This is the access key from the storage account

.PARAMETER StorageContainer
This is the name of blob container where the files reside

.PARAMETER FilesOlderThan
This specifies blob files older than 'x' that you'd like to remove from the container

.EXAMPLE
How to use within Azure DevOps Pipelines
Remove-AzStorageBlobs -StorageAccount $(StorageAccount) -StorageAccountKey $(StorageAccountKey) -StorageContainer $(StorageContainer) -FilesOlderThan $(FilesOlderThan)

The variable $(StorageAccount) will be similar to "dasprdtprstr","daspptprstr", or "dasdevgrafstr"
The variable $(StorageAccountKey) will be similar to [string of characters  equating to the Access Key of the Stroage Account]
The variable $(StorageContainer) will be similar to "tpr", or "alerts"
The variable $(FilesOlderThan) will specify blobs older then 'x' days will be deleted
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccount,
    [Parameter(Mandatory = $true)]
    [string]$SASToken,
    [Parameter(Mandatory = $true)]
    [string]$StorageContainer,
    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [string]$FilesOlderThan,
    [Parameter(Mandatory = $false)]
    [ValidateNotNull()]
    [string]$FilesToIgnore,
    [Parameter(Mandatory = $false)]
    [bool]$DryRun = $true
)

# Creating the Storage Context and setting up to be able to list the Blobs in the Container
try {

    If ($DryRun) {
        Write-Warning "Processing DryRun..."
    }

    $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccount -SasToken $SASToken
    $AzStorageContainer = Get-AzStorageContainer -Container $StorageContainer -Context $StorageContext
    if (!$AzStorageContainer) {
        throw "Storage container not found"
    }

    Foreach ($File in (Get-AzStorageBlob -Container $StorageContainer -Context $StorageContext | Where-Object { [string]::IsNullOrEmpty($FilesOlderThan) -or $_.LastModified -lt ((Get-Date).AddDays($FilesOlderThan)) })) {
        if ([string]::IsNullOrEmpty($FilesToIgnore) -or (!($FilesToIgnore.Replace(" ", "") -split (',') | Where-Object { $File.Name -like $_ }))) {
            Write-Output "Deleting -> $($File.Name)"
            if (!$DryRun) {
                try {
                    #$AzStorageContainer | Get-AzStorageBlob -Blob $($File.Name) | Remove-AzStorageBlob -ErrorAction Continue -WhatIf
                    Remove-AzStorageBlob -Blob $File.Name -Container $StorageContainer -Context $StorageContext -ErrorAction Continue -WhatIf
                }
                catch {
                    "Unable to delete $($File.Name), details below"
                    $_
                }
            }
        }
        else {
            Write-Output "Skipping -> $($File.Name)"
        }
  }
}
catch {
    throw "$_"
}
