<#
.SYNOPSIS
Create A Sql Database Service Account Automation

.DESCRIPTION
Create A Sql Database Service Account Automation

.PARAMETER ServerName
Name of the SQL Server

.PARAMETER AzureFireWallName
Name of the tempoary Sql Server FireWall rule created (Optional)

.PARAMETER SqlServiceAccountName
The name of the service account to be created.

.PARAMETER Environment
The Environment of the New Service account,

.PARAMETER KeyVaultName
The name of the Keyvault for the Environment


.EXAMPLE
$New-SqlDBAccountParameters = @{
	 ServerName = ServerName
     DataBaseName = DataBaseName
     SqlServiceAccountName = SqlServiceAccountName
     Enviroment = Enviroment
     KeyVaultName = KeyVaultName
}

.\New-SqlDbServiceAccount.ps1 @New-SqlDBAccountParameters

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]$ServerName,
    [Parameter(Mandatory = $false)]
    [String]$AzureFirewallName = "AzureWebAppFirewall",
    [Parameter(Mandatory = $true)]
    [String]$DataBaseName,
    [Parameter(Mandatory = $true)]
    [String]$SqlServiceAccountName,
    [Parameter(Mandatory = $true)]
    [String]$Enviroment,
    [Parameter(Mandatory = $true)]
    [String]$KeyVaultName
)

$ErrorActionPreference = 'Stop'

function New-AzureSQLServerFirewallRule {
    $AgentIP = (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]"
    New-AzureRmSqlServerFirewallRule -StartIPAddress $AgentIp -EndIPAddress $AgentIp -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
}
function Update-AzureSQLServerFirewallRule {
    $AgentIP = (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]"
    Set-AzureRmSqlServerFirewallRule -StartIPAddress $AgentIp -EndIPAddress $AgentIp -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
}
function Get-RandomPassword {
    $Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | Sort-Object { Get-Random })[0..33] -join ''
    return $Password
}
function Remove-AzureSQLServerFirewallRule {
    if ((Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $SQLResourceGroup -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue)) {
        Remove-AzureRmSqlServerFirewallRule -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
    }
}

try {

    $ServiceAccountSecretName = "$Enviroment-$SqlServiceAccountName".ToLower()
    $ServerFQDN = "$ServerName.database.windows.net"

    # --- Retrieve SQL Server details
    Write-Host "Searching for server resource $($ServerName)"
    $ServerResource = Get-AzureRmResource -Name $ServerName -ResourceType "Microsoft.Sql/servers"
    if (!$ServerResource) {
        throw "Could not find SQL server with name $ServerName"
    }

    Write-Host "Retrieving server login details"
    $SqlServerUserName = (Get-AzureRmSqlServer -ResourceGroupName $ServerResource.ResourceGroupName -ServerName $ServerName).SqlAdministratorLogin

    Write-Host "Retrieving secure server password"
    $SqlServerPassword = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $ServerName).SecretValueText
    if (!$SqlServerPassword) {
        throw "Could not retrieve secure password for $ServerName"
    }

    # --- Add agent IP exception to the firewall
    if (!(Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $ServerResource.ResourceGroupName -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue)) {
        New-AzureSQLServerFirewallRule
    }
    else {
        Update-AzureSQLServerFirewallRule
    }

    # --- Retrieve or set service account password
    $ServiceAccountPassword = (Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $ServiceAccountSecretName).SecretValueText
    if (!$ServiceAccountPassword) {
        $AccountPassword = Get-RandomPassword
        $SecureAccountPassword = $AccountPassword | ConvertTo-SecureString -AsPlainText -Force
        Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $SecureAccountPassword
    }

    # --- Execute query
    $Query = @"
    IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE NAME = '$($SqlServiceAccountName)') BEGIN
        CREATE USER "$($SqlServiceAccountName)" WITH PASSWORD = '$($AccountPassword)';
    END

    ALTER ROLE db_datareader
        ADD MEMBER "$($SqlServiceAccountName)"

    ALTER ROLE db_datawriter
        ADD MEMBER "$($SqlServiceAccountName)"

    GRANT EXECUTE TO "$($SqlServiceAccountName)"
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

    Write-Host "##vso[task.setvariable variable=SQLServerServiceAccountUsername]$SqlServiceAccountName"
    Write-Host "##vso[task.setvariable variable=SQLServerServiceAccountPassword;issecret=true]$AccountPassword"
}
catch {
    throw "$_"
}
finally {
    Remove-AzureSQLServerFirewallRule
}
