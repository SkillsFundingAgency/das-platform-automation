<#
    .SYNOPSIS
    Adds an Azure SQL database to an existing SQL failover group.

    .DESCRIPTION
    Resolves the primary SQL server name from deployment parameters, locates the target failover group, and adds the specified database when it is not already present. If the SQL server resource group parameter is not provided, the script automatically discovers the resource group for the SQL server.

    .PARAMETER ServerName
    Base SQL server name from pipeline parameters. The script derives the West Europe primary server name by appending '-we'.

    .PARAMETER DatabaseName
    Name of the Azure SQL database to add to the failover group.

    .PARAMETER FailoverGroupName
    Name of the Azure SQL failover group that should contain the database.

    .PARAMETER SqlServerResourceGroupName
    Optional resource group containing the SQL server. If omitted, the script detects it dynamically.

    .EXAMPLE
    Add-SqlDatabaseFailover -ServerName "das-foo-shared-sql" -DatabaseName "das-env-foo-db" -FailoverGroupName "das-foo-shared-sql"
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ServerName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$FailoverGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$SqlServerResourceGroupName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$DatabaseName
)

$failoverGroup = Get-AzSqlDatabaseFailoverGroup `
    -ResourceGroupName $SqlServerResourceGroupName `
    -ServerName $ServerName `
    -FailoverGroupName $FailoverGroupName `
    -ErrorAction Stop

$databaseResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$SqlServerResourceGroupName/providers/Microsoft.Sql/servers/$ServerName/databases/$DatabaseName"

if ($failoverGroup.Databases -contains $databaseResourceId) {
    Write-Output "Database '$DatabaseName' is already in failover group '$FailoverGroupName'."
}
else {
    $database = Get-AzSqlDatabase `
        -ResourceGroupName $SqlServerResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -ErrorAction Stop

    Add-AzSqlDatabaseToFailoverGroup `
        -ResourceGroupName $SqlServerResourceGroupName `
        -ServerName $ServerName `
        -FailoverGroupName $FailoverGroupName `
        -Database $Database `
        -ErrorAction Stop
    Write-Output "Added '$DatabaseName' to failover group '$FailoverGroupName'."
}