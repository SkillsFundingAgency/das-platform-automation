<#
.SYNOPSIS
Create A Sql Database Service Account Automation

.DESCRIPTION
Create A Sql Database Service Account Automation

.PARAMETER ServerNamr
Name of the SQL Server 

.PARAMETER AzureFirewallName
Name of the tempoary Sql Server Firewall rule created 

.PARAMETER SqlUserName
Sql Server Master User Name 

.PARAMETER SqlPassword
Sql Server Master Password.

.PARAMETER SqlServiceAccountName
The name of the service account to be created.

.Parameter SQLResourceGroup
The Resource group of the SQL Server

.PARAMETER Enviroment
The Enviroment of the New Service account,

.PARAMETER KeyVaultName
The name of the Keyvault for the Enviroment


.EXAMPLE

.\Create-SqlDbServiceAccount.ps1  -ServerName ServerName `
                                   -DataBaseName DataBaseName `
                                   -SqlUserName SqlUserName `
                                   -SqlPassword SqlPassword `
                                   -SqlServiceAccountName SqlServiceAccountName `
                                   -SQLResourceGroup SQLResourceGroup
                                   -Enviroment Enviroment
                                   -KeyVaultName KeyVaultName

#>

[CmdletBinding(DefaultParameterSetName = 'None')]
param
(
  [String] [Parameter(Mandatory = $true)] $ServerName,
  [String] $AzureFirewallName = "AzureWebAppFirewall",
  [String] [Parameter(Mandatory = $true)] $DataBaseName,
  [String] [Parameter(Mandatory = $true)] $SqlUserName,
  [SecureString] [Parameter(Mandatory = $true)] $SqlPassword,
  [String] [Parameter(Mandatory = $true)] $SqlServiceAccountName,
  [String] [Parameter(Mandatory = $true)] $SQLResourceGroup,
  [String] [Parameter(Mandatory = $true)] $Enviroment,
  [String] [Parameter(Mandatory = $true)] $KeyVaultName
)

$ErrorActionPreference = 'Stop'


function New-AzureSQLServerFirewallRule {
  $agentIP = (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]"
  New-AzureRmSqlServerFirewallRule -StartIPAddress $agentIp -EndIPAddress $agentIp -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
}
function Update-AzureSQLServerFirewallRule{
  $agentIP= (New-Object net.webclient).downloadstring("http://checkip.dyndns.com") -replace "[^\d\.]"
  Set-AzureRmSqlServerFirewallRule -StartIPAddress $agentIp -EndIPAddress $agentIp -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
}

function Get-RandomPassword{
  $Password = ([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | Sort-Object {Get-Random})[0..33] -join ''
  return $Password
}
function Invoke-SqlQuery([String] $query) {
  $output = Invoke-Sqlcmd -ServerInstance $ServerFQDN -Database $DataBaseName -Username $SqlUserName -Password $SqlPassword -OutputSqlErrors $true -Query $query
  return $output
}

function Remove-AzureSQLServerFirewallRule {
   If ((Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $SQLResourceGroup -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue))
    {
      Remove-AzureRmSqlServerFirewallRule -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
    }
}

try {
$AccountExistQuery = "SELECT * 
FROM sys.database_principals
WHERE name = '$SqlServiceAccountName'"


$secretName = "${Enviroment}-${SqlServiceAccountName}"

Write-host "$secretName"

If ((Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $SQLResourceGroup -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue) -eq $null)
{
  New-AzureSQLServerFirewallRule
}
else
{
  Update-AzureSQLServerFirewallRule
}

Write-host "$ServerName.database.windows.net"
$ServerFQDN = "$ServerName.database.windows.net"
$accountExist = Invoke-SqlQuery $AccountExistQuery 
Write-Output $accountExist


if ($accountExist) {
  $AccountPassword = Get-AzureKeyVaultSecret -VaultName $KeyVaultName -name $secretName 
  $query = "ALTER USER `"$SqlServiceAccountName`" WITH PASSWORD = `'$AccountPassword`' "
  Invoke-SqlQuery -query $query
}
else {
  $AccountPassword = Get-RandomPassword 
  $aecure = $AccountPassword  |ConvertTo-SecureString -AsPlainText -Force 
  Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $secretName -SecretValue $aecure 
  $query = "CREATE USER `"$SqlServiceAccountName`"  WITH PASSWORD = `'$AccountPassword`' "
 Invoke-SqlQuery -query $query 
  $query2 = "ALTER ROLE db_datareader ADD MEMBER `"$SqlServiceAccountName`" "
  Invoke-SqlQuery -query $query2
  $query3 = "ALTER ROLE db_datawriter ADD MEMBER `"$SqlServiceAccountName`" "
  Invoke-SqlQuery -query $query3
  $query4 = "GRANT EXECUTE TO `"$SqlServiceAccountName`" "
  Invoke-SqlQuery -query $query4
}

Write-Host "##vso[task.setvariable variable=SQLServerServiceAccountUsername]$SqlServiceAccountNames"
Write-Host "##vso[task.setvariable variable=secretSauce;issecret=true]$AccountPassword"
Remove-AzureSQLServerFirewallRule
}
catch {
  throw "$_"
}

