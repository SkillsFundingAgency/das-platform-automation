Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AzSqlIpException Unit Tests" -Tags @("Unit") {
    $Params = @{
        WhatsMyIpUrl      = "https://not-a-real-web.com"
        ServerName        = "das-myserver"
        ResourceGroupName = "das-foo-rg"
        Name              = "rule1"
    }

    Mock Get-AzSqlServerFirewallRule -MockWith {
        return @{
            "ResourceGroupName" = "das-foo-rg"
            "Servername"        = "das-myserver"
            "FirewallRuleName"  = "rule1"
        }
    }

    Mock Remove-AzSqlServerFirewallRule -MockWith {
        return @{
            "ResourceGroupName" = "das-foo-rg"
            "Servername"        = "das-myserver"
            "FirewallRuleName"  = "rule1"
        }
    }

    Context "Whats My Ip Service doesn't return a response" {
        Mock Invoke-RestMethod -MockWith { return "1.2.4.5" }
        It "Throws an error with the message 'Unable to retrieve valid IP address using https://not-a-real-api.com, returned.'" {
            { ./Remove-AzSqlIpException.ps1 @Params } | Should Not throw
            Assert-MockCalled Get-AzSqlServerFirewallRule -Exactly 1 -Scope It
            Assert-MockCalled Remove-AzSqlServerFirewallRule -Exactly 1 -Scope It
        }
    }
    Context "Whats My Ip Service throws response" {
        Mock Invoke-RestMethod -MockWith { return "bvasfdh%" }
        It "Throws an error with the message 'Unable to retrieve valid IP address using https://not-a-real-api.com, returned.'" {
            { ./Remove-AzSqlIpException.ps1 @Params } | Should throw
            Assert-MockCalled Get-AzSqlServerFirewallRule -Exactly 1 -Scope It
            Assert-MockCalled Remove-AzSqlServerFirewallRule -Exactly 0 -Scope It
        }
    }

}