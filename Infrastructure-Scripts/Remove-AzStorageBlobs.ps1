<#
.SYNOPSIS
Deleted blobs from specified storage container

.DESCRIPTION
This script will remove all files from the specified container. It will be able to be used in an Azure DevOps release pipeline.

.PARAMETER StorageAccount
This is the name of the storage account which will contain the storage container

.PARAMETER SASToken
This is the SAS Token for the storage account

.PARAMETER StorageContainer
This is the name of blob container where the files reside

.PARAMETER FilesToIgnore
This specifies the file to ignore. Accepts comma delimited and wildcards e.g *.csv

.PARAMETER FilesOlderThan
This specifies blob files older than 'x' that you'd like to remove from the container

.PARAMETER DryRun
This defaults to True so file deletion will only occur if passed in as false

.EXAMPLE
How to use within Azure DevOps Pipelines
Remove-AzStorageBlobs -StorageAccount $(StorageAccount) -StorageAccountKey $(StorageAccountKey) -StorageContainer $(StorageContainer) -FilesOlderThan $(FilesOlderThan) -DryRun $false

The variable $(StorageAccount) will be similar to "dasprdtprstr","daspptprstr", or "dasdevgrafstr"
The variable $(StorageAccountKey) will be similar to [string of characters  equating to the Access Key of the Stroage Account]
The variable $(StorageContainer) will be similar to "tpr", or "alerts"
The variable $(FilesOlderThan) will specify blobs older then 'x' days will be deleted
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "Known bug - https://github.com/PowerShell/PSScriptAnalyzer/issues/1472")]
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
    $StorageBlob = Get-AzStorageBlob -Container $StorageContainer -Context $StorageContext

    if (!$StorageBlob) {
        throw("Could not find Storage Container: $StorageContainer")
    }

    Foreach ($File in ($StorageBlob | Where-Object { [string]::IsNullOrEmpty($FilesOlderThan) -or $_.LastModified -lt ((Get-Date).AddDays($FilesOlderThan)) })) {
        if ([string]::IsNullOrEmpty($FilesToIgnore) -or (!($FilesToIgnore.Replace(" ", "") -split (',') | Where-Object { $File.Name -like $_ }))) {
            Write-Output "Deleting -> $($File.Name)"
            if (!$DryRun) {
                try {
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
    throw $_
}