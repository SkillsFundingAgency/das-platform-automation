<#
    .SYNOPSIS
    Parses a JSON schema file into a configuration object and populates this with values from environment variables.

    .DESCRIPTION
    Parses a JSON schema file into a configuration object and populates this with values from environment variables.  Intended for use in Azure DevOps pipelines.
    Will first try to get values from Azure DevOps variables before trying to get them from environment variables.  In this way Azure DevOps secret variables can be
    accessed by mapping them to environment variables as part of a task definition.

    After generation the configuration object is written to an Azure Storage Table.

    .PARAMETER SourcePath
    The path to the directory containing the schema file.

    .PARAMETER TargetFilename
    The filename of the schema.

    .PARAMETER StorageAccountName
    The name of the Azure Storage Account that contains the Table.

    .PARAMETER StorageAccountResourceGroup
    The name of the resource group containing the Storage Account.

    .PARAMETER EnvironmentName
    The environment the configuration is being created in, used as the Partition Key in the Storage Table.

    .PARAMETER TableName
    The table name, defaults to Configuration.

    .PARAMETER Version
    The configuration version, used as part of the row name.  Defaults to '1.0'.

    .EXAMPLE
    $NewConfigurationTableEntry = @{
        SourcePath = "$(Pipeline.Workspace)/foo-bar-config/Configuration/foo-bar-web"
        TargetFilename = "FOO.BAR.Web.schema.json"
        StorageAccountName = "fooconfigstr"
        StorageAccountResourceGroup = "foo-config-rg"
        EnvironmentName   = "BAR"
    }
    .\New-ConfigurationTableEntry.ps1 @NewConfigurationTableEntry
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$SourcePath,
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$TargetFilename,
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$StorageAccountName,
    [Parameter(Mandatory = $True)]
    [ValidateNotNullOrEmpty()]
    [String]$StorageAccountResourceGroup,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$EnvironmentName,
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$TableName = "configuration",
    [Parameter(Mandatory = $False)]
    [ValidateNotNullOrEmpty()]
    [String]$Version = "1.0"
)

Import-Module $PSScriptRoot/tools/Helpers.psm1 -Force

# --- TODO: Test if source path is a directory
if (!$SourcePath.EndsWith("/")) {
    $SourcePath = "$($SourcePath)/"
}

$SchemaPath = "$($SourcePath)$($TargetFilename)"
$Schemas = Get-ChildItem -Path $SchemaPath -File -Recurse

foreach ($Schema in $Schemas) {

    $Configuration = Build-ConfigurationEntity -SchemaDefinitionPath $Schema.FullName
    Test-ConfigurationEntity -Configuration $Configuration -SchemaDefinitionPath $Schema.FullName

    $NewEntityParameters = @{
        StorageAccountName = $StorageAccountName
        StorageAccountResourceGroup = $StorageAccountResourceGroup
        TableName      = $TableName
        PartitionKey   = $EnvironmentName
        RowKey         = "$($Schema.BaseName.Replace('.schema',''))_$($Version)"
        Configuration  = $Configuration
    }
    New-ConfigurationEntity @NewEntityParameters
}
