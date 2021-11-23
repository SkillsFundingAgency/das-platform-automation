$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AzSqlIpException Unit Tests" -Tags @("Unit") {

    $env:RELEASE_REQUESTEDFOR = $Config.ruleName
    $Params = @{
        StartIpAddress = $Config.ipAddress
        EndIPAddress   = $Config.ipAddress
        servername     = $Config.servername
        Name           = "TestUser"
    }

    Context "Remove firewall rulename on a sql server" {
        It "Should remove firewall rule on the given server name" {

            Mock Get-AzSqlServerFirewallRule -MockWith {
                return @{
                    "ResourceGroupName" = $Config.resourceGroupName
                    "Servername"        = $Config.serverName
                    "FirewallRuleName"  = $Config.rulename
                }
            }
        }
        Mock Remove-AzSqlServerFirewallRule -MockWith { return $null }
        { ./Remove-AzSqlIpException @Params } | Should Not throw
        Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
        Assert-MockCalled -CommandName 'Get-AzSqlServerFirewallRule' -Times 1 -Scope It
        Assert-MockCalled -CommandName 'Remove-AzSqlServerFirewallRule' -Times 1 -Scope It
    }
}




