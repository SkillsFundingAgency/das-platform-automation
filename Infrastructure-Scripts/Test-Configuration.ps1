<#

.SYNOPSIS
This script will validate a configuration file against its associated schema

.DESCRIPTION
This script will validate a configuration file against its associated schema

.PARAMETER Path
The path of the directory that will be recursively searched, defaulting to current working directory

.PARAMETER SchemaFileNameFilter
The filter for the schema file names, defaulting to *.schema.json

.EXAMPLE
./Test-Configuration.ps1 -Path ./folder1 -SchemaFileNameFilter "*firewallRules.schema.json"

#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",
    [Parameter(Mandatory = $false)]
    [string]$SchemaFileNameFilter = "*.schema.json"
)

function Test-Configuration ($Path, $SchemaFileNameFilter) {
    $Schemas = Get-ChildItem -Path $Path -Filter $SchemaFileNameFilter -Recurse
    foreach ($Schema in $Schemas) {
        Write-Output "-> Processing schema $($Schema.FullName)"
        $SchemaJson = Get-Content -Path $Schema.FullName -Raw
        $SchemaObject = $SchemaJson | ConvertFrom-Json
        if ($SchemaObject.validateFiles) {
            foreach ($SchemaFilePattern in $SchemaObject.validateFiles) {
                $SchemaFilePath = "$($Schema.Directory.FullName)\$SchemaFilePattern"
                $ValidateFiles = Get-ChildItem $SchemaFilePath -File | Where-Object { $_.Name -notlike "*.schema.json" }
                if ($ValidateFiles.Count -lt 1) {
                    throw "No schema files found to validate in $SchemaFilePath."
                }
                else {
                    foreach ($File in $ValidateFiles) {
                        $ConfigJson = Get-Content -Path $File.FullName -Raw
                        Write-Output "  -> Validating file $($File.Name)"
                        $null = Test-Json -Json $ConfigJson -SchemaFile $Schema.FullName
                    }
                }
            }
        }
    }
}

try {
    Test-Configuration -Path $Path -SchemaFileNameFilter $SchemaFileNameFilter
}
catch {
    Write-Error $_.Exception.Message
    throw $_
}
