$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Set-AzResourceGroupTags.ps1 Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "Should create a new Resource Group with 3 tags" {
            Mock Get-AzResourceGroup -MockWith { Return $null }
            Mock New-AzResourceGroup -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Tags"              = @{
                        Environment        = $Config.environment
                        'Parent Business'  = $Config.parentBusinessTag
                        'Service Offering' = $Config.serviceOffering
                    }
                }
            }
            $Result = ./Set-AzResourceGroupTags -ResourceGroupName $Config.resourceGroupName -Tags '{"Environment" = $Config.environment; "Parent Business" = $Config.parentBusinessTag; "Service Offering" = $Config.serviceOffering}'
            $Result.Tags.Count | Should Be 3
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'New-AzResourceGroup' -Times 1 -Scope It
        }
    }

    Context "Resource Group exists" {
        It "Should add or update an existing Resource Groups set of tags" {
            Mock Get-AzResourceGroup -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                }
            }
            Mock Set-AzResourceGroup -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                }
            }
            { ./Set-AzResourceGroupTags -ResourceGroupName $Config.resourceGroupName -Tags '{"Environment" = $Config.environment; "Parent Business" = $Config.parentBusinessTag; "Service Offering" = $Config.serviceOffering}' } | Should Not Throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzResourceGroup' -Times 1 -Scope It
        }
    }

}
