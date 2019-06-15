<#
#>

try {
    Import-Module $PSScriptRoot\InitializationHelpers.psm1 -Force

    Initialize-TaskDependencies -Verbose:$VerbosePreference
    Initialize-Azure

    Trace-VstsEnteringInvocation $MyInvocation

    $SourcePath = Get-VstsInput -Name SourcePath -Require
    $TargetFilename = Get-VstsInput -Name TargetFilename -Require
    $AzureConnectedServiceNameSelector = Get-VstsInput -Name ConnectedServiceNameSelector -Require
    $TableName = Get-VstsInput -Name TableName -Require
    $EnvironmentName = (Get-VstsTaskVariable -Name EnvironmentName).ToUpper()

    switch ($AzureConnectedServiceNameSelector) {
        "ARM" {
            $AzureStorageAccount = Get-VstsInput -Name StorageAccountRM -Require
            $ServiceEndpointName = Get-VstsInput -Name ARM -require
            break
        }
        "ASM" {
            $AzureStorageAccount = Get-VstsInput -Name StorageAccount -Require
            $ServiceEndpointName = Get-VstsInput -Name ASM -require
            break
        }
    }

    $ConnectionString = Get-StorageAccountConnectionString -Name $AzureStorageAccount -Type $AzureConnectedServiceNameSelector

    $NewEnvironmentConfigurationTableEntryParameters = @{
        SourcePath       = $SourcePath
        TargetFilename   = $TargetFilename
        ConnectionString = $ConnectionString
        TableName        = $TableName
        EnvironmentName  = $EnvironmentName
    }

    New-EnvironmentConfigurationTableEntry @NewEnvironmentConfigurationTableEntryParameters
}
catch {
    throw  $_
}
finally {
    Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
    Remove-EndpointSecrets
    Disconnect-AzureAndClearContext -ErrorAction SilentlyContinue
}
