# --- Dot source handlers
Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 -File | ForEach-Object {
    . $_.FullName
}

# --- Configuration Handlers
Export-ModuleMember -Function Test-EnvironmentConfigurationEntity
Export-ModuleMember -Function Test-EnvironmentConfigurationEntity
Export-ModuleMember -Function New-EnvironmentConfigurationEntity
Export-ModuleMember -Function New-EnvironmentConfigurationTableEntry

# --- Schema Property Handlers
Export-ModuleMember -Function Get-SchemaPropertyValue
Export-ModuleMember -Function Expand-SchemaProperty

# --- Storage Account Handlers
Export-ModuleMember -Function Set-TableStorageEntity
Export-ModuleMember -Function Get-StorageAccountConnectionString
