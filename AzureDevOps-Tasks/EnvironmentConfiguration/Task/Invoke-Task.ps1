<#
#>
try {
    Trace-VstsEnteringInvocation $MyInvocation

    Import-Module -Name $PSScriptRoot\InitializationHelpers.psm1 -Force
    Initialize-TaskDependencies -Verbose:$VerbosePreference

    if ($ENV:TF_BUILD) {

        # --- Inputs
        $SourcePath = Get-VstsInput -Name SourcePath -Require
        $TargetFilename = Get-VstsInput -Name TargetFilename -Require
        $TableName = Get-VstsInput -Name TableName -Require

        $StorageAccount = Get-VstsInput -Name StorageAccountName -Require
        $ServiceEndpointName = Get-VstsaInput -Name ServiceConnectionName -require

        # --- Variables
        $EnvironmentName = (Get-VstsTaskVariable -Name EnvironmentName).ToUpper()
        if (!$EnvironmentName) {
            $EnvironmentName = (Get-VstsTaskVariable -Name RELEASE_ENVIRONMENTNAME).ToUpper()
        }

        Write-Host "Im here"

        # --- Init
        $Endpoint = Get-VstsEndpoint -Name $ServiceEndpointName -Require
        Initialize-AzModule -Endpoint $Endpoint -AzVersion 1.6.0
    }

    $NewEnvironmentConfigurationTableEntryParameters = @{
        SourcePath      = $SourcePath
        TargetFilename  = $TargetFilename
        StorageAccount  = $StorageAccount
        TableName       = $TableName
        EnvironmentName = $EnvironmentName
    }

    New-EnvironmentConfigurationTableEntry @NewEnvironmentConfigurationTableEntryParameters
}
catch {
    Write-Error -Message "$_" -ErrorAction Stop
}
finally {
    Trace-VstsLeavingInvocation $MyInvocation
}
