Import-Module "$PSScriptRoot\..\Infrastructure-Scripts\Set-AzSqlUser\tools\Helpers.psm1"
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\Set-AzSqlUser


Describe "Set-AzSqlUser unit tests" -Tag "Unit" {
    Mock Get-AzResource -MockWith {
        return @{
            Name = "das-foo-sql"
        }
    }

    Mock Invoke-SqlLogRedundantRoles -MockWith {
        return @{}
    }
    
    Mock Invoke-SqlLogRedundantGrants -MockWith {
        return @{}
    }

    Mock Get-AzAccessToken -MockWith {
        return @{
            Token = "token"
        }
    }

    $Params = @{
        SqlServer = "das-foo-sql"
        SqlDatabaseName = "das-foo-db"
        Username = "foo-bar"

        DryRun = $true
    }

    Context "Create user with role and grants" {
        It "Create user with role but no grants" {
            $Params["Roles"] = "db_datawriter"
            $Params["Grants"] = $null

            ./Set-AzSqlUser @Params

            Assert-MockCalled -CommandName Invoke-SqlLogRedundantRoles -Times 1 -Scope It 
            Assert-MockCalled -CommandName Invoke-SqlLogRedundantGrants -Times 1 -Scope It

        }

        It "Create user with grants but no roles" {
            $Params.Remove("Roles")
            $Params["Grants"] = "bar"

            ./Set-AzSqlUser @Params

            Assert-MockCalled -CommandName Invoke-SqlLogRedundantRoles -Times 1 -Scope It 
            Assert-MockCalled -CommandName Invoke-SqlLogRedundantGrants -Times 1 -Scope It

        }

        It "Create user with multiple roles and multiple grants" {
            $Params["Roles"] = "db_datareader", "db_datawriter"
            $Params["Grants"] = "Grant1", "Grant2"

            ./Set-AzSqlUser @Params

            Assert-MockCalled -CommandName Invoke-SqlLogRedundantRoles -Times 1 -Scope It 
            Assert-MockCalled -CommandName Invoke-SqlLogRedundantGrants -Times 1 -Scope It

        }

        It "Create user with multiple grants on schemas objects" {
            $Params.Remove("Roles")
            $Params["Grants"] = "Grant1-Table1", "Grant2-View2"

            ./Set-AzSqlUser @Params

            Assert-MockCalled -CommandName Invoke-SqlLogRedundantRoles -Times 1 -Scope It 
            Assert-MockCalled -CommandName Invoke-SqlLogRedundantGrants -Times 1 -Scope It

        }

    }

    Context "Create user with unallowed roles" { 
        It "Create user with unallowed roles" {
            $Params["Roles"] = "db_owner"

            { ./Set-AzSqlUser @Params } | Should Throw

        }
    }

}