$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Scripts\Infrastructure\

Describe "Set-AzResourceTags.ps1 Unit Tests" -Tags @("Unit") {

    Context "ResourceGroup has no tags" {
        It "Should Output a no tags Warning" {
            Mock Get-AzResourceGroup -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                }
            }
            $result =./Set-AzResourceTags -ResourceGroupName $Config.resourceGroupName
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
        }
    }

    Context "Resource Group has Tags" {
        It "Should add or update tags from resourcegroup to resources" {
            Mock Get-AzResourceGroup -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Tags"              = @{
                        Environment        = $Config.environment
                        'Parent Business'  = $Config.parentBusinessTag
                        'Service Offering' = $Config.serviceOffering
                    }
                }
            }
            Mock Get-AzResource -MockWith {
                return @{
                    "ResourceName" = $Config.resourceName
                    "ResourceId" = $Config.resourceId
                    "Tags"              = @{}
                    }
                }
            Mock Set-AzResource -MockWith {
                return @{
                    "ResourceName" = $Config.resourceName
                    "ResourceId" = $Config.resourceId
                    "Tags"              = @{
                        Environment        = $Config.environment
                        'Parent Business'  = $Config.parentBusinessTag
                        'Service Offering' = $Config.serviceOffering
                    }
                }
            }
            { ./Set-AzResourceTags -ResourceGroupName $Config.resourceGroupName } | Should Not Throw
            Assert-MockCalled -CommandName 'Get-AzResourceGroup' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzResource' -Times 2 -Scope It
            Assert-MockCalled -CommandName 'Set-AzResource' -Times 1 -Scope It
        }
    }

}
