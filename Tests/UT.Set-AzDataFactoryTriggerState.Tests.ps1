$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Set-AzDataFactoryTriggerState.ps1 Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "The specified Resource Group was not found in the subscription, throw an error" {
            Mock Get-AzResourceGroup -MockWith { Return $null }
            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState Disable } | Should throw "Resource Group $($Config.resourceGroupName) does not exist."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
        }
    }

    Context "Resource Group exists but not the DataFactory" {

        It "The Resource Group Exists But Not the DataFactory throw error" {
            Mock Get-AzResourceGroup -MockWith {
                $ResourceGroupExist = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new($Config.location, $null, $Config.resourceGroupName)
                return $ResourceGroupExist
            }
            Mock Get-AzDataFactoryV2 -MockWith { Return $null }
            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState Disable } | Should throw "The Data Factory $($Config.DataFactoryName) in Resource Group $($Config.resourceGroupName) Does not exists."
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2' -Times 1 -Scope It
        }
    }

    Context "Resource Group exists and DataFactory exists but no Triggers Associated with the DataFactory" {

        It "Should Output Warning but not throw error if No Triggers associated with Data Factory" {
            Mock Get-AzResourceGroup -MockWith { Return $Config.ResourceGroupName }
            Mock Get-AzDataFactoryV2 -MockWith { Return $Config.DataFactoryName }
            Mock Get-AzDataFactoryV2Trigger -MockWith { Return $null }
            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState Disable } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2Trigger' -Times 1 -Scope It
        }
    }

    Context "Triggers Exists within DataFactory and Trigger State is enable" {
        It "Should Enable Triggers if they exists" {
            Mock Get-AzResourceGroup -MockWith { Return $Config.ResourceGroupName }
            Mock Get-AzDataFactoryV2 -MockWith { Return $Config.DataFactoryName }
            Mock Get-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @{
                    name  = "aTrigger"
                    _name = "aTrigger"
                }
                return $Trigger
            }
            Mock Start-AzDataFactoryV2Trigger  -MockWith {
                $Trigger = @{
                    name  = "aTrigger"
                    _name = "aTrigger"
                }
                return $Trigger
            }

            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState enable } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2Trigger' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Start-AzDataFactoryV2Trigger' -Times 1 -Scope It
        }
    }

    Context "Triggers Exists within DataFactory and Trigger State is disable" {
        It "Should Disable Triggers if they exist" {
            Mock Get-AzResourceGroup -MockWith { Return $Config.ResourceGroupName }
            Mock Get-AzDataFactoryV2 -MockWith { Return $Config.DataFactoryName }
            Mock Get-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @{
                    name  = "aTrigger"
                    _name = "aTrigger"
                }
                return $Trigger
            }
            Mock Stop-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @{
                    name  = "aTrigger"
                    _name = "aTrigger"
                }
                return $Trigger
            }
            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState Disable } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2Trigger' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Stop-AzDataFactoryV2Trigger' -Times 1 -Scope It
        }
    }
    Context "Triggers Exists within DataFactory and Trigger State is disable with multiple triggers" {
        It "Should Disable Triggers if they exist" {
            Mock Get-AzResourceGroup -MockWith { Return $Config.ResourceGroupName }
            Mock Get-AzDataFactoryV2 -MockWith { Return $Config.DataFactoryName }
            Mock Get-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @(
                    [PSCustomObject]@{
                        'name' = 'Trigger1'
                    }
                    [PSCustomObject]@{
                        'name' = 'Trigger2'
                    }
                )
                return $Trigger
            }
            Mock Stop-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @{
                    name  = "aTrigger"
                    _name = "aTrigger"
                }
                return $Trigger
            }
            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState Disable } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2Trigger' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Stop-AzDataFactoryV2Trigger' -Times 2 -Scope It
        }
    }
    Context "Triggers Exists within DataFactory and Trigger State is enable with multiple triggers" {
        It "Should Disable Triggers if they exist" {
            Mock Get-AzResourceGroup -MockWith { Return $Config.ResourceGroupName }
            Mock Get-AzDataFactoryV2 -MockWith { Return $Config.DataFactoryName }
            Mock Get-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @(
                    [PSCustomObject]@{
                        'name' = 'Trigger1'
                    }
                    [PSCustomObject]@{
                        'name' = 'Trigger2'
                    }
                )
                return $Trigger
            }
            Mock Start-AzDataFactoryV2Trigger -MockWith {
                $Trigger = @{
                    name  = "aTrigger"
                    _name = "aTrigger"
                }
                return $Trigger
            }
            { ./Set-AzDataFactoryTriggerState -DataFactoryName $Config.DataFactoryName -ResourceGroupName $Config.ResourceGroupName -TriggerState enable } | Should Not throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzDataFactoryV2Trigger' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Start-AzDataFactoryV2Trigger' -Times 2 -Scope It
        }
    }
}
