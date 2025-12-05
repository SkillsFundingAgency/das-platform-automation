$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Invoke-SqlAutoscaling Unit Tests" -Tags @("Unit") {

    Context "No scaling when thresholds not met" {
        It "Should not scale when active messages are between thresholds" {
            # Mock Get-AutomationVariable for all parameters
            Mock Get-AutomationVariable -MockWith {
                param($Name)
                switch ($Name) {
                    'Autoscale_ResourceGroup' { return $Config.resourceGroupName }
                    'Autoscale_SqlServerName' { return $Config.serverName }
                    'Autoscale_DbName' { return "TestDb" }
                    'Autoscale_SecondarySqlServerName' { return $null }
                    'Autoscale_SecondaryDbName' { return $null }
                    'Autoscale_HasSecondary' { return $false }
                    'Autoscale_SbNamespace' { return $Config.NamespaceName }
                    'Autoscale_SbQueue' { return "TestQueue" }
                    'Autoscale_ScaleUpThreshold' { return 100 }
                    'Autoscale_ScaleDownThreshold' { return 10 }
                    'Autoscale_SustainedUpMinutes' { return 0 }
                    'Autoscale_SustainedDownMinutes' { return 0 }
                    'Autoscale_ScaleUpTarget' { return "S3" }
                    'Autoscale_ScaleDownTarget' { return "S1" }
                    default { return "TestValue" }
                }
            }

            # Mock Azure cmdlets
            Mock Connect-AzAccount -MockWith { return $null }
            Mock Write-Output -MockWith { return $null }

            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 50
                    }
                }
            }

            Mock Get-AzSqlDatabase -MockWith {
                return @{
                    CurrentServiceObjectiveName = "S2"
                }
            }

            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 50
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            Mock Set-AzSqlDatabase -MockWith { return $null }

            { ./Invoke-SqlAutoscaling.ps1 } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }
    }
}
