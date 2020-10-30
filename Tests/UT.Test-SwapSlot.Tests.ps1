Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Test-SwapSlot Unit Tests" -Tags @("Unit") {
    Mock Get-AzWebAppAccessRestrictionConfig -MockWith {
        return @{
            ResourceGroupName = "das-test-ass-rg"
            WebAppName = "das-test-assapi-as"
            SlotName = "staging"
            MainSiteAccessRestrictions = @(
                @{
                    RuleName = "Allow all"
                    Description = "Allow all access"
                    Action = "Allow"
                    Priority = 1
                    IpAddress = "Any"
                    SubnetId = $null
                }
            )
            ScmSiteAccessRestrictions = @(
                @{
                    RuleName = "Allow all"
                    Description = "Allow all access"
                    Action = "Allow"
                    Priority = 1
                    IpAddress = "Any"
                    SubnetId = $null
                }
            )
            ScmSiteUseMainSiteRestrictionConfig = $False
        }
    }
    Mock Add-AzWebAppAccessRestrictionRule
    Mock Invoke-WebRequest
    Mock Restart-AzWebAppSlot
    Mock Remove-AzWebAppAccessRestrictionRule

    $Params = @{
        WhatsMyIpServiceUrl = "https://not-a-real-api.com"
        AppServiceName = "das-foo-appservice-as"
        ResourceGroupName = "das-foo-appservice-rg"
    }

    Context "Whats My Ip Service doesn't return a response" {
        Mock Invoke-RestMethod -MockWith { return $null}
        It "Throws an error with the message 'Unable to retrieve valid IP address using https://not-a-real-api.com, returned.'" {
            { ./Test-SwapSlot.ps1 @Params } | Should throw
            Assert-MockCalled Get-AzWebAppAccessRestrictionConfig -Exactly 1 -Scope It
            Assert-MockCalled Add-AzWebAppAccessRestrictionRule -Exactly 0 -Scope It
            Assert-MockCalled Restart-AzWebAppSlot -Exactly 0 -Scope It
        }
    }

    Context "Whats My Ip Service returns an invalid response" {
        Mock Invoke-RestMethod -MockWith { "foo.bar.bar.foo" }
        It "Throws an error with the message 'Unable to retrieve valid IP address using https://not-a-real-api.com, foo.bar.bar.foo returned.'" {
            { ./Test-SwapSlot.ps1 @Params } | Should throw
            Assert-MockCalled Get-AzWebAppAccessRestrictionConfig -Exactly 1 -Scope It
            Assert-MockCalled Add-AzWebAppAccessRestrictionRule -Exactly 0 -Scope It
            Assert-MockCalled Restart-AzWebAppSlot -Exactly 0 -Scope It
        }
    }

    Context "Whats My Ip Service returns a valid response and webapp has access restrictions" {
        Mock Invoke-RestMethod -MockWith { "192.168.0.1" }
        Mock Get-AzWebAppAccessRestrictionConfig -MockWith {
            return @{
                ResourceGroupName = "das-test-ass-rg"
                WebAppName = "das-test-assapi-as"
                SlotName = "staging"
                MainSiteAccessRestrictions = @(
                    @{
                        RuleName = "GatewaySubnet"
                        Description = ""
                        Action = "Allow"
                        Priority = 100
                        IpAddress =$null
                        SubnetId = "/subscriptions/a-sub/resourceGroups/a-rg/providers/Microsoft.Network/virtualNetworks/a-vnet/subnets/a-sn"
                    },
                    @{
                        RuleName = "Deny all"
                        Description = "Deny all access"
                        Action = "Deny"
                        Priority = 2147483647
                        IpAddress = "Any"
                        SubnetId = $null
                    }
                )
                ScmSiteAccessRestrictions = @(
                    @{
                        RuleName = "Allow all"
                        Description = "Allow all access"
                        Action = "Allow"
                        Priority = 1
                        IpAddress = "Any"
                        SubnetId = $null
                    }
                )
                ScmSiteUseMainSiteRestrictionConfig = $False
            }
        }
        Mock Write-Output 
        It "Writes CompleteSwap true to Azure DevOps variable" {
            
            ./Test-SwapSlot.ps1 @Params -Verbose
            Assert-MockCalled Get-AzWebAppAccessRestrictionConfig -Exactly 1 -Scope It
            Assert-MockCalled Add-AzWebAppAccessRestrictionRule -Exactly 0 -Scope It
            Assert-MockCalled Restart-AzWebAppSlot -Exactly 0 -Scope It
            Assert-MockCalled -Exactly 1 -Scope It -ParameterFilter { $InputObject -eq "##vso[task.setvariable variable=CompleteSwap]true" }
        }
    }

}