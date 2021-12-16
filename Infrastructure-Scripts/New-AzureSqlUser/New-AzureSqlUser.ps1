[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$Database,
    [Parameter(Mandatory=$true)]
    [ValidateSet("at","test","test2","demo","pp","prd","mo", IgnoreCase = $false)]
    [String]$Environment,
    [Parameter(Mandatory=$true)]
    [String]$SQLServerName,
    [Parameter(Mandatory=$true)]
    [String]$SqlUsersConfigurationFilePath
)

# get config
$SqlUsersConfiguration = Get-Content -Path $SqlUsersConfigurationFilePath -Raw | ConvertFrom-Json
## filter out $Users for this $Database from config
$ConfigDatabaseUsers = $SqlUsersConfiguration | Where-Object { $Database -match "^das-\w{2,3}$($_.databaseNameSuffix)$" }

# --- Build generic SQL CMD parameters object
$SqlCmdParameters = @{
    ServerInstance    = "$SQLServerName.database.windows.net"
    Database          = $Database
    EncryptConnection = $true
    AccessToken = (Get-AzAccessToken -ResourceUrl https://database.windows.net).Token
}

$SqlCmdParameters["InputFile"] = "$PSScriptRoot\sql\get-all-users.sql"
$ExistingDatabaseUsers = Invoke-Sqlcmd @SqlCmdParameters

$SqlCmdParameters["InputFile"] = "$PSScriptRoot\sql\get-all-roles.sql"
$ExistingRoles = Invoke-Sqlcmd @SqlCmdParameters

$SqlCmdParameters["InputFile"] = "$PSScriptRoot\sql\get-all-grants.sql"
$ExistingGrants = Invoke-Sqlcmd @SqlCmdParameters

foreach ($User in $ConfigDatabaseUsers) {
    Remove-Variable ConfigureUserStatement -ErrorAction SilentlyContinue
    $ConfigureUserStatement = ""
    ##TO DO: decide on best way to handle the 2 types of userName value - fullname & suffix.  Is additional validation required for fullname?
    if ($User.userName -match "^[-\w{2,}]{1,}-\w{2,}$") {
        $UserName = "das-$Environment$($User.userName)"
    }
    else {
        $UserName = $User.userName
    }
    Write-Output "Processing user: $UserName"
    
    ## construct SQL script
    if ($UserName -in $ExistingDatabaseUsers.name) {
        Write-Output "---> $UserName already exists"
    }
    else {
        Write-Output "---> $UserName doesn't exist, adding CREATE USER statement"
        $ConfigureUserStatement += "CREATE USER [$UserName] FROM EXTERNAL PROVIDER;`n"
    }

    $ExistingUserRoles = $ExistingRoles | Where-Object { $_.DatabaseUserName -eq $UserName }
    foreach ($Role in $User.roles) {
        if ($Role -in $ExistingUserRoles.DatabaseRoleName) {
            Write-Output "---> $UserName is already a member of $Role"
        }
        else {
            Write-Output "---> $UserName is not a member of $Role, adding ALTER ROLE statement"
            $ConfigureUserStatement += "ALTER ROLE $Role ADD MEMBER [$UserName];`n"
        }
    }
    ##TO DO: check that ExistingUserRoles doesn't contain roles not in config and REVOKE

    $ExistingUserGrants = $ExistingGrants | Where-Object { $_.DatabaseUserName -eq $UserName }
    foreach ($Grant in $User.grants) {
        if ($Grant.objects.Count -eq 0) {
            if ($Grant.permission -in $ExistingUserGrants.PermissionName) {
                Write-Output "---> $UserName has already been granted $($Grant.permission)"
            }
            else {
                Write-Output "---> $UserName has not been granted $($Grant.permission), adding GRANT statement"
                $ConfigureUserStatement += "GRANT $($Grant.permission) TO [$UserName];`n"
            }
        }
        else {
            foreach ($Object in $Grant.objects) {
                Remove-Variable MatchingGrant -ErrorAction SilentlyContinue
                $MatchingGrant = $ExistingUserGrants | Where-Object { $_.PermissionName -eq $Grant.Permission -and $_.ObjectName -eq $Object }
                if ($MatchingGrant) {
                    Write-Output "---> $UserName has already been granted $($Grant.permission) on $Object"
                }
                else {
                    Write-Output "---> $UserName has not been granted $($Grant.permission) on $Object, adding GRANT statement"
                    $ConfigureUserStatement += "GRANT $($Grant.permission) ON $Object TO [$UserName];`n"
                } 
            }
        }
        ##TO DO: check that ExistingUserGrants doesn't have GRANTS (on everything and on objects) not in config and REVOKE
    }

    if ($ConfigureUserStatement) {
        Write-Verbose "Executing configure user script:`n$ConfigureUserStatement"
        ## execute SQL script
        Write-Output "---> Applying changes to $UserName"
        $SqlCmdParameters.Remove("InputFile")
        $SqlCmdParameters["Query"] = $ConfigureUserStatement
        Invoke-Sqlcmd @SqlCmdParameters -ErrorAction Stop
        $SqlCmdParameters.Remove("Query")
    }
    else {
        Write-Output "---> No changes to make on $UserName"
    }
    ## clear SQL script
    Remove-Variable ConfigureUserStatement -ErrorAction SilentlyContinue
}


