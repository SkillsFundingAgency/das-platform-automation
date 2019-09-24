$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Set-AzResourceGroupTags.ps1 Unit Tests" -Tags @("Unit") {

    Context "Resource Group does not exist" {
        It "Should create a new Resource Group with 3 tags" {
            Mock Get-AzResourceGroup -MockWith { Return $null }
            Mock New-AzResourceGroup -MockWith {
                $Tags = New-Object 'system.collections.generic.dictionary[string,string]'
                $Tags.Add("Environment", $Config.environment)
                $Tags.Add("Parent Business", $Config.parentBusinessTag)
                $Tags.Add("Service Offering", $Config.serviceOffering)
                $ResourceGroup = [Microsoft.Azure.Management.ResourceManager.Models.ResourceGroup]::new($Config.location, $null, $Config.resourceGroupName, $null, $null, $Tags)
                return $ResourceGroup
            }
            $Result = ./Set-AzResourceGroupTags -ResourceGroupName $Config.resourceGroupName -Environment $Config.environment -ParentBusiness $Config.parentBusinessTag -ServiceOffering $Config.serviceOffering
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
            { ./Set-AzResourceGroupTags -ResourceGroupName $Config.resourceGroupName -Environment $Config.environment -ParentBusiness $Config.parentBusinessTag -ServiceOffering $Config.serviceOffering } | Should Not Throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzResourceGroup' -Times 1 -Scope It
        }

    }

}
