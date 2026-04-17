<#
    .SYNOPSIS
    Adds an Azure SQL database to an existing SQL failover group.

    .DESCRIPTION
    Adds a newly created SQL Database to the shared SQL Server failover group.

    .PARAMETER SharedSQLServerName
    Name of Primary SQL Server that the database is created on.

    .PARAMETER DatabaseName
    Name of the Azure SQL database to add to the failover group.

    .PARAMETER FailoverGroupName
    Name of the Azure SQL failover group that should contain the database.

    .PARAMETER SqlServerResourceGroupName
    Resource group containing the SQL server

    .EXAMPLE
    .\Add-SqlDatabaseFailover.ps1 -sharedSQLServerName "das-foo-shared-sql-we" -databasename "das-env-foo-db" -failovergroupname "das-env-shared-sql" -sqlserverresourcegroupname "das-env-shared-rg"
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$SharedSQLServerName,
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
    -ServerName $SharedSQLServerName `
    -FailoverGroupName $FailoverGroupName `
    -ErrorAction Stop

$databaseResourceId = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$SqlServerResourceGroupName/providers/Microsoft.Sql/servers/$SharedSQLServerName/databases/$DatabaseName"

if ($failoverGroup.Databases -contains $databaseResourceId) {
    Write-Output "Database '$DatabaseName' is already in failover group '$FailoverGroupName'."
}
else {
    $database = Get-AzSqlDatabase `
        -ResourceGroupName $SqlServerResourceGroupName `
        -ServerName $SharedSQLServerName `
        -DatabaseName $DatabaseName `
        -ErrorAction Stop

    Add-AzSqlDatabaseToFailoverGroup `
        -ResourceGroupName $SqlServerResourceGroupName `
        -ServerName $SharedSQLServerName `
        -FailoverGroupName $FailoverGroupName `
        -Database $Database `
        -ErrorAction Stop
    Write-Output "Added '$DatabaseName' to failover group '$FailoverGroupName'."
}