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

.\New-SqlDbServiceAccount.ps1  -ServerName ServerName `
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
    [Parameter(Mandatory = $true)]
    [String] $ServerName,
    [String] $AzureFirewallName = "AzureWebAppFirewall",
    [Parameter(Mandatory = $true)]
    [String]  $DataBaseName,
    [Parameter(Mandatory = $true)]
    [String]$SqlUserName,
    [Parameter(Mandatory = $true)]
    [SecureString]  $SqlPassword,
    [Parameter(Mandatory = $true)]
    [String]  $SqlServiceAccountName,
    [Parameter(Mandatory = $true)]
    [String]  $SQLResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]  $Enviroment,
    [Parameter(Mandatory = $true)]
    [String] $KeyVaultName
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
function Invoke-SqlQuery([String] $Query) {
    $Output = Invoke-Sqlcmd -ServerInstance $ServerFQDN -Database $DataBaseName -Username $SqlUserName -Password $SqlPassword -OutputSqlErrors $true -Query $Query
    return $Output
}

function Remove-AzureSQLServerFirewallRule {
    If ((Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $SQLResourceGroup -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue)) {
        Remove-AzureRmSqlServerFirewallRule -FirewallRuleName $AzureFirewallName -ServerName $ServerName -ResourceGroupName $SQLResourceGroup
    }
}

try {
    $AccountExistQuery = @"
                        SELECT * FROM sys.database_principals WHERE name = '$SqlServiceAccountName'
"@

    $SecretName = "${Enviroment}-${SqlServiceAccountName}"

    Write-Host "$SecretName"

    If ((Get-AzureRmSqlServerFirewallRule -ServerName $ServerName -ResourceGroupName $SQLResourceGroup -FirewallRuleName $AzureFirewallName -ErrorAction SilentlyContinue) -eq $null) {
        New-AzureSQLServerFirewallRule
    }
    else {
        Update-AzureSQLServerFirewallRule
    }

    Write-Host "$ServerName.database.windows.net"
    $ServerFQDN = "$ServerName.database.windows.net"
    $AccountExist = Invoke-SqlQuery $accountExistQuery
    Write-Output $accountExist


    if ($AccountExist) {
		Write-Host "Account Exists"
    }
    else {
        $AccountPassword = Get-RandomPassword
        $SecureAccountPassword = $AccountPassword | ConvertTo-SecureString -AsPlainText -Force
        Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $SecureAccountPassword
        $Query = @"
                    CREATE USER "$SqlServiceAccountName"  WITH PASSWORD = '$AccountPassword'
                    ALTER ROLE db_datareader ADD MEMBER "$SqlServiceAccountName"
                    ALTER ROLE db_datawriter ADD MEMBER "$SqlServiceAccountName"
                    GRANT EXECUTE TO "$SqlServiceAccountName"
"@
        Invoke-SqlQuery -query $Query
    }

    Write-Host "##vso[task.setvariable variable=SQLServerServiceAccountUsername]$SqlServiceAccountName"
    Write-Host "##vso[task.setvariable variable=secretSauce;issecret=true]$AccountPassword"
    Remove-AzureSQLServerFirewallRule
}
catch {
    throw "$_"
}

