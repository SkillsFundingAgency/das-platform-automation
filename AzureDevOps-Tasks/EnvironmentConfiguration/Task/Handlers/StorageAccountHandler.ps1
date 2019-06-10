function Set-TableStorageEntity {
    <#
	#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ConnectionString,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$TableName,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$PartitionKey,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$RowKey,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Configuration
    )

    try {

        $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
        $StorageTable = Get-AzureStorageTable -Context $StorageContext -Name $TableName

        $Entity = ($StorageTable.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Retrieve($PartitionKey, $RowKey))).Result

        if ($Entity) {
            Write-Host "Updating existing entity"
            $Entity.Properties["Data"].StringValue = $Configuration
            $null = $StorageTable.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::InsertOrReplace($Entity))
        }
        else {
            Write-Host "Creating a new entity"
            $Entity = [Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity]::new($PartitionKey, $RowKey)
            $Entity.Properties.Add("Data", $Configuration)
            $null = $StorageTable.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($Entity))
        }
    }
    catch {
        throw $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Get-StorageAccountConnectionString {
    <#
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet("ARM", "ASM")]
        [String]$Type
    )

    try {
        switch ($Type) {
            'ARM' {
                $StorageAccount = Get-AzureRmResource -Name $Name -ResourceType "Microsoft.Storage/storageAccounts" -ErrorAction Stop
                $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $Name)[0].Value
                break
            }

            'ASM' {
                $StorageAccountKey = (Get-AzureStorageKey -StorageAccountName $Name).Primary
                break
            }
        }

        Write-Output $StorageAccountKey

    }
    catch {
        throw "Could not retrieve storage account for $($Name): $($_.Exception.Message)"
    }
}
