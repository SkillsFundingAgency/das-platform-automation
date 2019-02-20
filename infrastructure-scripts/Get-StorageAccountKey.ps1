<#

.SYNOPSIS
Return either the Primary or Seconday connection String to the Consig Storage account and Write to a VSTS variable.

.DESCRIPTION
Return either the Primary or Seconday connection String to the Consig Storage account and Write to a VSTS variable.

.PARAMETER Name
The name of the Storage Account

.PARAMETER useSecondary
Boolean Switch to Return Secondary String

.EXAMPLE
.\Get-GetStorageAccountKey.ps1  -Name stracc

.EXAMPLE
.\Get-GetStorageAccountKey.ps1 -Name stracc -useSecondary

.EXAMPLE
.\Get-GetStorageAccountKey.ps1  -Name stracc -OutputVariable "CustomOutputVariable"

#>

Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    [Parameter(Mandatory = $false)]
    [switch]$UseSecondary,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
	[String]$OutputVariable = "StorageConnectionString"
)

try {

    # --- Check if storage account exists in our subscription
    Write-Host "Checking for existing Storage Account"
    $StorageAccount = Get-AzureRmResource -ResourceName $Name -ErrorAction SilentlyContinue

    # --- If the Storage Account doesn't exist, erorr
    if (!$StorageAccount) {
       throw "StorageAccount $Name Does not exist"
    }

    # --- Get the key and set the env variable
    $Key = Invoke-AzureRmResourceAction -Action listKeys -ResourceType "Microsoft.ClassicStorage/storageAccounts" -ApiVersion "2016-11-01" -ResourceGroupName $($StorageAccount.ResourceGroupName) -ResourceName $($StorageAccount.Name) -force

    if ($UseSecondary.IsPresent) {
        $ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($Name);AccountKey=$($Key.SecondaryKey)"
    }
    else {
        $ConnectionString = "DefaultEndpointsProtocol=https;AccountName=$($Name);AccountKey=$($Key)"
    }

    Write-Output ("##vso[task.setvariable variable=$($OutputVariable);issecret=true]$($ConnectionString)")
}
catch {
    throw "$_"
}
