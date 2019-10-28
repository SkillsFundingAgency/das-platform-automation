function Get-StorageAccountKey {
    <#
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name
    )

    try {
        Trace-VstsEnteringInvocation $MyInvocation

        $StorageAccount = Get-AzResource -Name $Name -ResourceType "Microsoft.Storage/storageAccounts" -ErrorAction Stop
        $StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $Name)[0].Value

        Write-Output $StorageAccountKey

    }
    catch {
        throw $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function Set-TableStorageEntity {
    <#
	#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$StorageAccount,
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

        Trace-VstsEnteringInvocation $MyInvocation
        $StorageAccountKey = Get-StorageAccountKey -Name $StorageAccount
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey

        $StorageTable = Get-AzStorageTable -Context $StorageContext -Name $TableName
        if (!$StorageTable){
            $StorageTable = New-AzStorageTable -Context $StorageContext -Name $TableName
        }

        $Entity = ($StorageTable.CloudTable.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::Retrieve($PartitionKey, $RowKey), $null, $null)).Result

        if ($Entity) {
            Write-Host "Updating existing entity [$RowKey]"
            $Entity.Properties["Data"].StringValue = $Configuration
            $null = $StorageTable.CloudTable.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($Entity))
        }
        else {
            Write-Host "Creating a new entity [$RowKey]"
            $Entity = [Microsoft.Azure.Cosmos.Table.DynamicTableEntity]::new($PartitionKey, $RowKey)
            $Entity.Properties.Add("Data", $Configuration)
            $null = $StorageTable.CloudTable.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($Entity))
        }
    }
    catch {
        throw $PSCmdlet.ThrowTerminatingError($_)
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}
