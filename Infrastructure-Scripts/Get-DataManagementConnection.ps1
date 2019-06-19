<#
.SYNOPSIS
Create A Sql Database Service Account Automation

.DESCRIPTION
Create A Sql Database Service Account Automation

.PARAMETER ServerName
Name of the SQL Server

.PARAMETER AzureFireWallName
Name of the temporary Sql Server FireWall rule created (Optional)

.PARAMETER SqlServiceAccountName
The name of the service account to be created.

.PARAMETER Environment
The Environment of the New Service account,

.PARAMETER KeyVaultName
The name of the Keyvault for the Environment


.EXAMPLE
$New-SqlDBAccountParameters = @{
	 ServerName = $ServerName
	 ReadOnlyReplica = $ReadOnlyReplica
	 DataBaseName = $DataBaseName
	 WareHouseDatabase = $WareHouseDatabase
     SqlServiceAccountName = $SqlServiceAccountName
     Environment = $Environment
     KeyVaultName = $KeyVaultName
}

.\New-SqlDbServiceAccount.ps1 @New-SqlDBAccountParameters

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$ServerName,
    [Parameter(Mandatory = $true)]
    [String]$ReadOnlyReplica,
    [Parameter(Mandatory = $true)]
    [String]$KVSecretName,
    [Parameter(Mandatory = $false)]
    [String]$AzureFirewallName = "AzureWebAppFirewall",
    [Parameter(Mandatory = $true)]
    [String]$DataBaseName,
    [Parameter(Mandatory = $true)]
    [String]$WareHouseDatabase,
    [Parameter(Mandatory = $true)]
    [String]$SqlServiceAccountName,
    [Parameter(Mandatory = $true)]
    [String]$Environment,
    [Parameter(Mandatory = $true)]
    [String]$KeyVaultName
)

$ErrorActionPreference = 'Stop'

function Get-RandomPassword {
    $Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | Sort-Object { Get-Random })[0..33] -join ''
    return $Password
}

try {
    $AgentIP = (Invoke-WebRequest ifconfig.me/ip -UseBasicParsing).Content.Trim()
    $ServiceAccountSecretName = "$SqlServiceAccountName".ToLower()
    $ServerFQDN = "$ServerName.database.windows.net"

    # --- Retrieve SQL Server details
    Write-Host "Searching for server resource $($ServerName)"
    $ServerResource = Get-AzureRmResource -Name $ServerName
    if (!$ServerResource) {
        throw "Could not find SQL server with name $ServerName"
    }

    Write-Host "Retrieving server login details"
    $SqlServerUserName = (Get-AzureRmSqlServer -ResourceGroupName $ServerResource.ResourceGroupName -ServerName $ServerName).SqlAdministratorLogin

    Write-Host "Retrieving secure server password"
    $SqlServerPassword = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $KVSecretName).SecretValueText
    if (!$SqlServerPassword) {
        throw "Could not retrieve secure password for $ServerName"
    }

    # --- Add agent IP exception to the firewall
    Write-Host "Updating firewall rule with agent ip: $AgentIP"
    $FirewallUpdateParameters = @{
        StartIPAddress    = $AgentIp
        EndIPAddress      = $AgentIp
        FirewallRuleName  = $AzureFirewallName
        ServerName        = $ServerName
        ResourceGroupName = $ServerResource.ResourceGroupName
    }

    if (!(Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ServerResource.ResourceGroupName -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue)) {
        $null = New-AzureRmSqlServerFirewallRule @FirewallUpdateParameters
    }
    else {
        $null = Set-AzureRmSqlServerFirewallRule @FirewallUpdateParameters
    }

    # --- Retrieve or set service account password
    Write-Host "Creating service account: $SqlServiceAccountName"
    $ServiceAccountPassword = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $ServiceAccountSecretName).SecretValueText
    if (!$ServiceAccountPassword) {
        $ServiceAccountPassword = Get-RandomPassword
        $SecureAccountPassword = $ServiceAccountPassword | ConvertTo-SecureString -AsPlainText -Force
        $null = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $ServiceAccountSecretName -SecretValue $SecureAccountPassword
    }

    # --- Execute query
    $Query = @"
    IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE NAME = '$($SqlServiceAccountName)') BEGIN
        CREATE USER "$($SqlServiceAccountName)" WITH PASSWORD = '$($ServiceAccountPassword)';
    END

    ALTER ROLE db_datareader
        ADD MEMBER "$($SqlServiceAccountName)"

"@

    $SQLCmdParameters = @{
        ServerInstance  = $ServerFQDN
        Database        = $DataBaseName
        Username        = $SqlServerUserName
        Password        = $SqlServerPassword
        OutputSqlErrors = $true
        Query           = $Query
    }

    Invoke-Sqlcmd @SQLCmdParameters

    $ServiceName = $DataBaseName.Split("-")[2]
    $CredName = "$($ServiceName)DBRCred"

    Write-Host "Creating encryped Credential: $CredName using $SqlServiceAccountName"

    $Query = @"
	CREATE DATABASE SCOPED CREDENTIAL "$($CredName)"  WITH IDENTITY = '$($SqlServiceAccountName)',
	SECRET =  '$($ServiceAccountPassword)'
"@

    $SQLCmdParameters = @{
        ServerInstance  = $ServerFQDN
        Database        = $WareHouseDatabase
        Username        = $SqlServerUserName
        Password        = $SqlServerPassword
        OutputSqlErrors = $true
        Query           = $Query
    }
    Invoke-Sqlcmd @SQLCmdParameters


    $ConectionName = "$($ServiceName)DBConnection"
    $ReadOnlyReplicaFQN = "$($ReadonlyReplica).database.windows.net"

    Write-Host "Creating Extenal Data Source to: $DataBaseName on $ReadOnlyReplicaFQN using $CredName"

    $Query = @"
	CREATE EXTERNAL DATA SOURCE "$($ConectionName)" WITH
    (TYPE = RDBMS,
    LOCATION = '$($ReadOnlyReplicaFQN)',
    DATABASE_NAME = '$($DataBaseName)',
    CREDENTIAL =  "$($CredName)",
) ;
"@

    $SQLCmdParameters = @{
        ServerInstance  = $ServerFQDN
        Database        = $WareHouseDatabase
        Username        = $SqlServerUserName
        Password        = $SqlServerPassword
        OutputSqlErrors = $true
        Query           = $Query
    }

    Invoke-Sqlcmd @SQLCmdParameters

}
catch {
    throw "$_"
}
finally {
    $ServerResource = Get-AzureRmResource -Name $ServerName -ResourceType "Microsoft.Sql/servers"
    if ((Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ServerResource.ResourceGroupName -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue)) {
        $null = Remove-AzureRmSqlServerFirewallRule -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $ServerResource.ResourceGroupName
    }
}
