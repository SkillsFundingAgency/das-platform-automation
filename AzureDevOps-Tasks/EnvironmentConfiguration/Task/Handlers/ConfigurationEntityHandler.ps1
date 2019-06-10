function Test-EnvironmentConfigurationEntity {
    <#
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [String]$Configuration,
        [Parameter(Mandatory = $True)]
        [Newtonsoft.Json.Schema.JSchema, Newtonsoft.Json.Schema, Version = 3.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]$SchemaObject
    )

    try {
        Write-Host "Validating configuration against schema"
        $ConfigurationObject = [Newtonsoft.Json.Linq.JToken]::Parse($Configuration)
        [Newtonsoft.Json.Schema.SchemaExtensions]::Validate($ConfigurationObject, $SchemaObject)

        Write-Host "Configuration validated!"
    }
    catch {
        throw "Could not validate configuration against the provided schema: $($_.Exception.InnerException.Message)"
    }
}

function New-EnvironmentConfigurationEntity {
    <#
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$SchemaDefinitionPath
    )

    try {
        foreach ($SchemaPath in $SchemaDefinitionPath) {

            Write-Host "Resolving schema definition"
            $ResolvedSchemaPath = (Resolve-Path -Path $SchemaPath).Path
            $SchemaDefinition = Get-Content -Path $ResolvedSchemaPath -Raw

            Write-Host "Parsing schema: $ResolvedSchemaPath"
            $SchemaObject = [Newtonsoft.Json.Schema.JSchema, Newtonsoft.Json.Schema, Version = 3.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Parse($SchemaDefinition)

            Write-Host "Processing schema properties"
            $Settings = [Newtonsoft.Json.JsonSerializerSettings]::new()
            $Settings.MaxDepth = 100
            $Configuration = [Newtonsoft.Json.JsonConvert]::SerializeObject((Expand-SchemaProperty -PropertyObject $SchemaObject.Properties), $Settings)

            Test-EnvironmentConfigurationEntity -Configuration $Configuration -SchemaObject $SchemaObject

            Write-Output $Configuration
        }
    }
    catch {
        throw $PSCmdlet.ThrowTerminatingError($_)
    }
}

function New-EnvironmentConfigurationTableEntry {
<#
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
        [String]$ConnectionString,
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [String]$EnvironmentName,
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [String]$TableName = "Configuration",
        [Parameter(Mandatory = $False)]
        [ValidateNotNullOrEmpty()]
        [String]$Version = "1.0"
    )

    try {
        $EnvironmentName = (Get-VstsTaskVariable -Name EnvironmentName).ToUpper()

        if (!$SourcePath.EndsWith("/")) {
            $SourcePath = "$($SourcePath)/"
        }

        $SchemaPath = "$($SourcePath)$($TargetFilename)"
        $Schemas = Get-ChildItem -Path $SchemaPath -File -Recurse | Select-Object -ExpandProperty FullName

        foreach ($Schema in $Schemas) {

            $Configuration = New-EnvironmentConfigurationEntity -SchemaDefinitionPath $Schema
            $RowKey = "$((Get-Item -Path $Schema).BaseName.Replace('.schema',''))_$($Version)"

            $SetEntityParameters = @{
                ConnectionType   = $null
                ConnectionString = $ConnectionString
                TableName        = $TableName
                PartitionKey     = $EnvironmentName
                RowKey           = $RowKey
                Configuration    = $Configuration
            }

            Set-TableStorageEntity @SetEntityParameters
        }
    }
    catch {
        throw $_
    }
}
