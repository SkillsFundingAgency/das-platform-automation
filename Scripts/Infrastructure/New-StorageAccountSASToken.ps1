<#
    .SYNOPSIS
    Create a new Storage Account level ad-hoc SAS token and write to a Azure Pipelines variable.

    .DESCRIPTION
    Create a new Storage Account level ad-hoc SAS token and write to a Azure Pipelines variable. Secured using the secondary account key.
    Use the -GenerateForSQLExternalDatasource switch to remove the ? character from the SAS token so that is can be used for SQL External Data Sources.
    Account SAS parameters: https://docs.microsoft.com/en-gb/rest/api/storageservices/create-account-sas?redirectedfrom=MSDN

    .PARAMETER ResourceGroup
    The name of the Resource Group that contains the Storage Account.

    .PARAMETER StorageAccount
    The name of the Storage Account.

    .PARAMETER Service
    Specify one or more of the following; Blob, File, Table, Queue.

    .PARAMETER ResourceType
    Specify one or more of the following; Service, Container, Object.

    .PARAMETER Permissions
    Specifies the signed permissions for the account level SAS token. Permissions are only valid if they match the specified signed resource type; otherwise they are ignored.
    Construct a string using the one or more of the following letters r (read), w (write), d (delete), l (list), a (add), c (create), u (update), p (process).
    For example rwd.

    .PARAMETER ExpiryInMinutes
    Specify in minutes how long the SAS token is valid for.

    .PARAMETER GenerateForSQLExternalDataSource
    Use this switch parameter to remove the ? character from the start of the SAS token so that it can be used for a SQL External Data Source.
    https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-access-to-data-in-azure-blob-storage?view=sql-server-ver15

    .PARAMETER OutputVariable
    The name of the variable to be used by Azure Pipelines. By default, this will be SASToken.

    .EXAMPLE
    .\New-StorageAccountSASToken.ps1 -ResourceGroup rgname -StorageAccount saname -Service blob -ResourceType container -Permissions rwd -ExpiryInMinutes 60

    Create a new SAS token with an expiry of 60 minutes to the specified service and resource type, with read, write and delete permissions.

    .EXAMPLE
    .\New-StorageAccountSASToken.ps1 -ResourceGroup rgname -StorageAccount saname -Service blob -ResourceType container -Permissions rwd -ExpiryInMinutes 5 -GenerateForSQLExternalDataSource

    Create a new SAS token with an expiry of 5 minutes to the specified service and resource type, with read, write and delete permissions.
    Prepare the SAS token for SQL External Data Source use.
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$ResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$StorageAccount,
    [Parameter(Mandatory = $true)]
    [ValidateSet("blob", "file", "table", "queue")]
    [string[]] $Service,
    [Parameter(Mandatory = $true)]
    [ValidateSet("service", "container", "object")]
    [string[]] $ResourceType,
    [Parameter(Mandatory = $true)]
    [string] $Permissions,
    [Parameter(Mandatory = $true)]
    [String]$ExpiryInMinutes,
    [Parameter(Mandatory = $false)]
    [switch]$GenerateForSQLExternalDataSource,
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String]$OutputVariable = "SASToken"
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

    else {
        # --- Storage Account exists, create a Storage context.
        $Key = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroup -Name $StorageAccount)[1].Value
        $StorageContext = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $Key

        # --- Create a SAS token.
        $SASToken = New-AzStorageAccountSASToken -Service $Service -ResourceType $ResourceType -Permission $Permissions -Context $StorageContext -Protocol HttpsOnly -ExpiryTime (Get-Date).AddMinutes($ExpiryInMinutes)

        # --- Remove the question mark from the start of the SAS token.
        if ($GenerateForSQLExternalDataSource.IsPresent) {
            $SASToken = $SASToken.Substring(1)
        }

        # --- Output the Azure Pipelines variable and SAS token as a secret value.
        Write-Output ("##vso[task.setvariable variable=$($OutputVariable);issecret=true]$($SASToken)")
    }

}

catch {
    throw "$_"
}
