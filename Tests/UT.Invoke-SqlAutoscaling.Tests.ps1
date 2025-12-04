$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

# Create function stub for Get-AutomationVariable to prevent parsing errors
# This must be defined before the script is parsed
if (-not (Get-Command Get-AutomationVariable -ErrorAction SilentlyContinue)) {
    function Get-AutomationVariable {
        param([string]$Name)
        switch ($Name) {
            'Autoscale_HasSecondary' { return $true }
            'Autoscale_ScaleUpThreshold' { return 100 }
            'Autoscale_ScaleDownThreshold' { return 10 }
            'Autoscale_SustainedUpMinutes' { return 5 }
            'Autoscale_SustainedDownMinutes' { return 10 }
            default { return "TestValue" }
        }
    }
}

Describe "Invoke-SqlAutoscaling Unit Tests" -Tags @("Unit") {

    $Params = @{
        ResourceGroup = $Config.resourceGroupName
        ServerName = $Config.serverName
        DbName = "TestDb"
        SecondaryServerName = "SecondaryServer"
        SecondaryDbName = "SecondaryDb"
        HasSecondary = $true
        SbResourceGroup = $Config.resourceGroupName
        SbNamespace = $Config.NamespaceName
        SbQueue = "TestQueue"
        ScaleUpThreshold = 100
        ScaleDownThreshold = 10
        SustainedUpMinutes = 5
        SustainedDownMinutes = 10
        ScaleUpTarget = "S3"
        ScaleDownTarget = "S1"
    }

    BeforeEach {
        Mock Get-AutomationVariable -MockWith {
            param($Name)
            switch ($Name) {
                'Autoscale_HasSecondary' { return $true }
                'Autoscale_ScaleUpThreshold' { return 100 }
                'Autoscale_ScaleDownThreshold' { return 10 }
                'Autoscale_SustainedUpMinutes' { return 5 }
                'Autoscale_SustainedDownMinutes' { return 10 }
                default { return "TestValue" }
            }
        }
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
                    },
                    [PSCustomObject]@{
                        Average = 55
                        TimeStamp = (Get-Date).ToUniversalTime()
                    }
                )
            }
        }
        Mock Set-AzSqlDatabase -MockWith { return $null }
    }

    Context "Scale up conditions met with secondary database" {
        It "Should scale up secondary first, then primary when conditions are met" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 150
                            TimeStamp = (Get-Date).ToUniversalTime()
                        },
                        [PSCustomObject]@{
                            Average = 155
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Connect-AzAccount' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzServiceBusQueue' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzSqlDatabase' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzMetric' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 2 -Scope It
        }
    }

    Context "Scale up conditions met without secondary database" {
        It "Should scale up primary only when no secondary exists" {
            $ParamsNoSecondary = $Params.Clone()
            $ParamsNoSecondary.HasSecondary = $false
            $ParamsNoSecondary.SecondaryServerName = $null
            $ParamsNoSecondary.SecondaryDbName = $null

            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 150
                            TimeStamp = (Get-Date).ToUniversalTime()
                        },
                        [PSCustomObject]@{
                            Average = 155
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @ParamsNoSecondary } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 1 -Scope It
        }
    }

    Context "Scale down conditions met with secondary database" {
        It "Should scale down primary first, then secondary when conditions are met" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 5
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 5
                            TimeStamp = (Get-Date).ToUniversalTime()
                        },
                        [PSCustomObject]@{
                            Average = 8
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 2 -Scope It
        }
    }

    Context "Scale down conditions met without secondary database" {
        It "Should scale down primary only when no secondary exists" {
            $ParamsNoSecondary = $Params.Clone()
            $ParamsNoSecondary.HasSecondary = $false
            $ParamsNoSecondary.SecondaryServerName = $null
            $ParamsNoSecondary.SecondaryDbName = $null

            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 5
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 5
                            TimeStamp = (Get-Date).ToUniversalTime()
                        },
                        [PSCustomObject]@{
                            Average = 8
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @ParamsNoSecondary } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 1 -Scope It
        }
    }

    Context "No scaling when already at target tier" {
        It "Should not scale when database is already at scale up target" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzSqlDatabase -MockWith {
                return @{
                    CurrentServiceObjectiveName = "S3"
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 150
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }

        It "Should not scale when database is already at scale down target" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 5
                    }
                }
            }
            Mock Get-AzSqlDatabase -MockWith {
                return @{
                    CurrentServiceObjectiveName = "S1"
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 5
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }
    }

    Context "No scaling when threshold not met" {
        It "Should not scale when active messages are below scale up threshold" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 50
                    }
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzMetric' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }

        It "Should not scale when active messages are above scale down threshold" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 50
                    }
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzMetric' -Times 0 -Scope It
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }
    }

    Context "No scaling when sustained metric condition not met" {
        It "Should not scale up when metric is not sustained above threshold" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 50
                            TimeStamp = (Get-Date).ToUniversalTime()
                        },
                        [PSCustomObject]@{
                            Average = 155
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }

        It "Should not scale down when metric is not sustained below threshold" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 5
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @(
                        [PSCustomObject]@{
                            Average = 5
                            TimeStamp = (Get-Date).ToUniversalTime()
                        },
                        [PSCustomObject]@{
                            Average = 15
                            TimeStamp = (Get-Date).ToUniversalTime()
                        }
                    )
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }
    }

    Context "Metric query returns no data" {
        It "Should not scale when metric query returns no data" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return $null
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }

        It "Should not scale when metric query returns no datapoints" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                return @{
                    Data = @()
                }
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }
    }

    Context "Metric query fails" {
        It "Should not scale when metric query throws an error" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            Mock Get-AzMetric -MockWith {
                throw "Metric query failed"
            }

            { ./Invoke-SqlAutoscaling.ps1 @Params } | Should Not throw
            Assert-MockCalled -CommandName 'Set-AzSqlDatabase' -Times 0 -Scope It
        }
    }

    Context "Sustained metric with zero duration" {
        It "Should return true immediately when duration is zero or less" {
            Mock Get-AzServiceBusQueue -MockWith {
                return @{
                    Id = "/subscriptions/test/resourceGroups/test/providers/Microsoft.ServiceBus/namespaces/test/queues/test"
                    CountDetails = @{
                        ActiveMessageCount = 150
                    }
                }
            }
            $ParamsZeroDuration = $Params.Clone()
            $ParamsZeroDuration.SustainedUpMinutes = 0

            { ./Invoke-SqlAutoscaling.ps1 @ParamsZeroDuration } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzMetric' -Times 1 -Scope It
        }
    }

}
