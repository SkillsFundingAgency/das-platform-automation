function Invoke-SqlCreateUser {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ServerInstance,
        [Parameter(Mandatory = $true)]
        [String]$Database,
        [Parameter(Mandatory = $true)]
        [String]$AccessToken,
        [Parameter(Mandatory = $true)]
        [String]$Username,
        [Parameter(Mandatory = $true)]
        [Bool]$DryRun
    )

    $SqlSpnCmdParameters = @{
        ServerInstance    = $ServerInstance
        Database          = $Database
        AccessToken       = $AccessToken
        EncryptConnection = $true
        InputFile         = "$PSScriptRoot\..\sql\add_mi_user.sql"
        Variable          = "Username=$Username"
    }

    if (!$DryRun) {
        Invoke-Sqlcmd @SqlSpnCmdParameters -ErrorAction Stop
    }
}

function Invoke-SqlAddRoles {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ServerInstance,
        [Parameter(Mandatory = $true)]
        [String]$Database,
        [Parameter(Mandatory = $true)]
        [String]$AccessToken,
        [Parameter(Mandatory = $true)]
        [String]$Username,
        [Parameter(Mandatory = $true)]
        [String[]]$Roles,
        [Parameter(Mandatory = $true)]
        [Bool]$DryRun
    )

    $SqlCmdParameters = @{
        ServerInstance    = $ServerInstance
        Database          = $Database
        AccessToken       = $AccessToken
        EncryptConnection = $true
        InputFile         = "$PSScriptRoot\..\sql\add_user_to_role.sql"
        Variable          = $null
    }

    foreach ($Role in $Roles) {
        Write-Host "  -> Adding $Username to role $Role"
        $SqlCmdParameters["Variable"] = "Username=$Username", "Role=$Role"
        if (!$DryRun) {
            Invoke-Sqlcmd @SqlCmdParameters -ErrorAction Stop
        }
    }
}

function Invoke-SqlAddGrants {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ServerInstance,
        [Parameter(Mandatory = $true)]
        [String]$Database,
        [Parameter(Mandatory = $true)]
        [String]$AccessToken,
        [Parameter(Mandatory = $true)]
        [String]$Username,
        [Parameter(Mandatory = $true)]
        [String[]]$Grants,
        [Parameter(Mandatory = $true)]
        [Bool]$DryRun
    )

    $SqlCmdParameters = @{
        ServerInstance    = $ServerInstance
        Database          = $Database
        AccessToken       = $AccessToken
        EncryptConnection = $true
        InputFile         = "$PSScriptRoot\..\sql\add_user_grant.sql"
        Variable          = $null
    }

    foreach ($Grant in $Grants) {
        $GrantName = ($Grant -split "-")[0]
        $GrantObject = ($Grant -split "-")[1]
        if ($GrantObject) {
            Write-Host "  -> Granting $GrantName on $GrantObject to $Username"
            $SqlCmdParameters["Variable"] = "Username=$Username", "Grant=$($GrantName.ToUpper())", "SchemaObject=$GrantObject"
            $SqlCmdParameters["InputFile"] = "$PSScriptRoot\..\sql\add_user_grant_object.sql"
            if (!$DryRun) {
                $null = Invoke-Sqlcmd @SqlCmdParameters -ErrorAction Stop
            }
        }
        else {
            Write-Host "  -> Granting $GrantName to $Username"
            $SqlCmdParameters["Variable"] = "Username=$Username", "Grant=$($Grant.ToUpper())"
            $SqlCmdParameters["InputFile"] = "$PSScriptRoot\..\sql\add_user_grant.sql"
            if (!$DryRun) {
                $null = Invoke-Sqlcmd @SqlCmdParameters -ErrorAction Stop
            }
        }
    }
}

function Invoke-SqlLogRedundantRoles {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ServerInstance,
        [Parameter(Mandatory = $true)]
        [String]$Database,
        [Parameter(Mandatory = $true)]
        [String]$AccessToken,
        [Parameter(Mandatory = $true)]
        [String]$Username,
        [Parameter(Mandatory = $true)]
        [String[]]$Roles,
        [Parameter(Mandatory = $true)]
        [Bool]$DryRun
    )

    $SqlCmdParameters = @{
        ServerInstance    = $ServerInstance
        Database          = $Database
        AccessToken       = $AccessToken
        EncryptConnection = $true
        InputFile         = "$PSScriptRoot\..\sql\log_redundant_roles.sql"
        Variable          = @("Username=$Username")
    }

    $Result = Invoke-Sqlcmd @SqlCmdParameters -ErrorAction Stop
    [System.Collections.ArrayList]$DatabaseRoles = $Result

    foreach ($Role in $Roles) {
        $RoleFound = $DatabaseRoles | Where-Object { $_.Role -eq $Role }
        if ($RoleFound) {
            $DatabaseRoles.Remove($RoleFound)
        }
    }

    $RedundantDatabaseRoles = $DatabaseRoles | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | ConvertFrom-Json
    Write-Host "##vso[task.setvariable variable=RedundantRoles;]$RedundantDatabaseRoles"
}

function Invoke-SqlLogRedundantGrants {
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$ServerInstance,
        [Parameter(Mandatory = $true)]
        [String]$Database,
        [Parameter(Mandatory = $true)]
        [String]$AccessToken,
        [Parameter(Mandatory = $true)]
        [String]$Username,
        [Parameter(Mandatory = $true)]
        [String[]]$Grants,
        [Parameter(Mandatory = $true)]
        [Bool]$DryRun
    )

    $SqlCmdParameters = @{
        ServerInstance    = $ServerInstance
        Database          = $Database
        AccessToken       = $AccessToken
        EncryptConnection = $true
        InputFile         = "$PSScriptRoot\..\sql\log_redundant_grants.sql"
        Variable          = "Username=$Username"
    }

    $Result = Invoke-Sqlcmd @SqlCmdParameters -ErrorAction Stop
    [System.Collections.ArrayList]$DatabaseGrants = $Result | Where-Object { $_.permission_name -ne "CONNECT" }
    foreach ($Grant in $Grants) {
        $GrantName = ($Grant -split "-")[0]
        $GrantObject = ($Grant -split "-")[1]
        if ($GrantObject) {
            $GrantFound = $DatabaseGrants | Where-Object { $_.permission_name -eq $GrantName -and $_.schema_object -eq $GrantObject }
        }
        else {
            $GrantFound = $DatabaseGrants | Where-Object { $_.permission_name -eq $GrantName -and $_.class_desc -eq "DATABASE" }
        }

        if ($GrantFound) {
            $DatabaseGrants.Remove($GrantFound)
        }
    }

    $RedundantDatabaseGrants = $DatabaseGrants | Select-Object * -ExcludeProperty ItemArray, Table, RowError, RowState, HasErrors | ConvertTo-Json | ConvertFrom-Json
    Write-Host "##vso[task.setvariable variable=RedundantGrants;]$RedundantDatabaseGrants"
}
