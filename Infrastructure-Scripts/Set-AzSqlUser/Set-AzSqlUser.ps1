<#
    .SYNOPSIS
    Grants Managed Identity access to a SQL database.

    .DESCRIPTION
    Grants Managed Identity access to a SQL database.

    .PARAMETER SqlServer
    Name of the SQL Server resource in azure eg: foo-bar-sql

    .PARAMETER SqlDatabaseName
    Name of the SQL database resource in azure eg: foo-bar-db

    .PARAMETER Username
    Name of the App Service/AAD group/Managed Identity to create and apply roles and grants to

    .PARAMETER Roles
    Roles to add to the user

    .PARAMETER Grants
    Grants to add to the user

    .PARAMETER DryRun
    Writes an output of the changes that would be made with no actual execution.

    .EXAMPLE
    .\Set-AzSqlUser.ps1 -SqlServer foo-bar-sql -SqlDatabaseName foo-bar-db -Username foobar -Roles "db_datawriter","db_datareader" -DryRun $true
    .\Set-AzSqlUser.ps1 -SqlServer foo-bar-sql -SqlDatabaseName foo-bar-db -Username foobar -Roles "db_datareader" -Grants "SHOWPLAN" -DryRun $true


    .Notes
    Ensure SQL Server is correctly configured with an MI as per https://docs.microsoft.com/en-us/azure/azure-sql/database/authentication-aad-service-principal

    Set-AzSqlServer -ResourceGroupName <ResourceGroupName> -ServerName <ServerName> -AssignIdentity

    The relevant service principal of the service connection is added as a member of the AAD Admin of the SQL server for this script to run.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$SqlServer,
    [Parameter(Mandatory = $true)]
    [String]$SqlDatabaseName,
    [Parameter(Mandatory = $true)]
    [String]$Username,
    [Parameter(Mandatory = $false)]
    [String[]]$Roles,
    [Parameter(Mandatory = $false)]
    [String[]]$Grants,
    [Parameter(Mandatory = $false)]
    [bool]$DryRun = $true
)

if ($DryRun) {
    Write-Host "-> Processing DryRun"
}
Import-Module "$PSScriptRoot\tools\Helpers.psm1" -Force

#Determine if server is in a failover group and return primary sql server if it is
Write-Output "-> Processing Server $SqlServer"
$SqlServerResources = Get-AzResource -Name "$SqlServer*" -ResourceType "Microsoft.Sql/servers"

if ($SqlServerResources.Count -gt 1) {
    $SqlServerResource = $SqlServerResources | Where-Object {
        $FailoverGroup = Get-AzSqlDatabaseFailoverGroup -ServerName $_.Name -ResourceGroupName $_.ResourceGroupName
        return ($FailoverGroup -and $FailoverGroup.ReplicationRole -eq "Primary")
    }
}
elseif ($SqlServerResources.Name.Count -eq 1) {
    # --- If there is only one, use that
    $SqlServerResource = $SqlServerResources[0]
}
else {
    throw "Could not find a Sql server with name $SqlServer"
}

$SqlSpnCmdParameters = @{
    ServerInstance = "$($SqlServerResource.Name).database.windows.net"
    Database       = $SqlDatabaseName
    AccessToken    = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
    Username       = $Username
}

#Add AAD group to database
Write-Output "  -> Adding $Username to $SqlDatabaseName if it doesnt exist"
Invoke-SqlCreateUser @SqlSpnCmdParameters -DryRun $DryRun

#Add Roles
if ($Roles) {
    Write-Output "    -> Adding roles for $Username if it doesnt exist"
    $null = Invoke-SqlAddRoles @SqlSpnCmdParameters -Roles $Roles -DryRun $DryRun

    Write-Output "    -> Log redundant user roles for $Username"
    $null = Invoke-SqlLogRedundantRoles @SqlSpnCmdParameters -Roles $Roles -DryRun $DryRun
}
else {
    Write-Output "    -> Log redundant user roles for $Username"
    $null = Invoke-SqlLogRedundantRoles @SqlSpnCmdParameters -Roles[] -DryRun $DryRun
}

#Add Grants
if ($Grants) {
    Write-Output "    -> Adding grants for $Username if it doesnt exist"
    $null = Invoke-SqlAddGrants @SqlSpnCmdParameters -Grants $Grants -DryRun $DryRun

    Write-Output "    -> Log redundant user grants for $Username"
    $null = Invoke-SqlLogRedundantGrants @SqlSpnCmdParameters -Grants $Grants -DryRun $DryRun
}
else {
    Write-Output "    -> Log redundant user grants for $Username"
    $null = Invoke-SqlLogRedundantGrants @SqlSpnCmdParameters -Grants [] -DryRun $DryRun
}