Describe "Add-SqlDatabaseFailover.ps1" {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot "../Infrastructure-Scripts/Add-SqlDatabaseFailover.ps1"
        $scriptPath = (Resolve-Path $scriptPath).Path

        if (-not (Test-Path $scriptPath)) {
            throw "Script under test not found at: $scriptPath"
        }

        $params = @{
            SharedSQLServerName        = "das-foo-shared-sql-we"
            FailoverGroupName          = "das-env-shared-sql"
            SqlServerResourceGroupName = "das-env-shared-rg"
            DatabaseName               = "das-env-foo-db"
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

            Assert-MockCalled Get-AzSqlDatabaseFailoverGroup -Times 1 -Exactly
            Assert-MockCalled Get-AzSqlDatabase -Times 0 -Exactly
            Assert-MockCalled Add-AzSqlDatabaseToFailoverGroup -Times 0 -Exactly
            Assert-MockCalled Write-Output -Times 1 -Exactly -ParameterFilter {
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

            Assert-MockCalled Get-AzSqlDatabaseFailoverGroup -Times 1 -Exactly
            Assert-MockCalled Get-AzSqlDatabase -Times 1 -Exactly
            Assert-MockCalled Add-AzSqlDatabaseToFailoverGroup -Times 1 -Exactly
            Assert-MockCalled Write-Output -Times 1 -Exactly -ParameterFilter {
                $InputObject -like "*Added*to failover group*"
            }
        }
    }
}
