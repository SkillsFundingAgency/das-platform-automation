# Requires -Version 5.1
# Pester 5.x

Describe "Add-SqlDatabaseFailover.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot "Add-SqlDatabaseFailover.ps1"
        if (-not (Test-Path $scriptPath)) {
            throw "Script under test not found at: $scriptPath"
        }

        $params = @{
            SharedSQLServerName       = "das-foo-shared-sql-we"
            FailoverGroupName         = "das-env-shared-sql"
            SqlServerResourceGroupName= "das-env-shared-rg"
            DatabaseName              = "das-env-foo-db"
        }

        $subscriptionId = "00000000-0000-0000-0000-000000000123"
        $databaseResourceId = "/subscriptions/$subscriptionId/resourceGroups/$($params.SqlServerResourceGroupName)/providers/Microsoft.Sql/servers/$($params.SharedSQLServerName)/databases/$($params.DatabaseName)"
    }

    Context "when database is already in the failover group" {
        BeforeEach {
            Mock Get-AzContext {
                [pscustomobject]@{
                    Subscription = [pscustomobject]@{ Id = $subscriptionId }
                }
            }

            Mock Get-AzSqlDatabaseFailoverGroup {
                [pscustomobject]@{
                    Databases = @($databaseResourceId)
                }
            }

            Mock Get-AzSqlDatabase {}
            Mock Add-AzSqlDatabaseToFailoverGroup {}
            Mock Write-Output {}
        }

        It "does not call Add-AzSqlDatabaseToFailoverGroup" {
            & $scriptPath @params

            Should -Invoke Get-AzSqlDatabaseFailoverGroup -Times 1 -Exactly
            Should -Invoke Get-AzSqlDatabase -Times 0
            Should -Invoke Add-AzSqlDatabaseToFailoverGroup -Times 0
            Should -Invoke Write-Output -Times 1 -ParameterFilter {
                $InputObject -like "*already in failover group*"
            }
        }
    }

    Context "when database is not in the failover group" {
        BeforeEach {
            Mock Get-AzContext {
                [pscustomobject]@{
                    Subscription = [pscustomobject]@{ Id = $subscriptionId }
                }
            }

            Mock Get-AzSqlDatabaseFailoverGroup {
                [pscustomobject]@{
                    Databases = @()
                }
            }

            Mock Get-AzSqlDatabase {
                [pscustomobject]@{ DatabaseName = $params.DatabaseName }
            }

            Mock Add-AzSqlDatabaseToFailoverGroup {}
            Mock Write-Output {}
        }

        It "fetches database and adds it to the failover group" {
            & $scriptPath @params

            Should -Invoke Get-AzSqlDatabaseFailoverGroup -Times 1 -Exactly
            Should -Invoke Get-AzSqlDatabase -Times 1 -Exactly
            Should -Invoke Add-AzSqlDatabaseToFailoverGroup -Times 1 -Exactly
            Should -Invoke Write-Output -Times 1 -ParameterFilter {
                $InputObject -like "*Added*to failover group*"
            }
        }
    }
}