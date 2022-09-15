function New-ConfigurationTableEntry {
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
}
