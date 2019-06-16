# --- Dot source handlers
Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 -File | ForEach-Object {
    . $_.FullName
}

Export-ModuleMember -Function @(
    # --- Configuration Handlers
    'Test-EnvironmentConfigurationEntity',
    'Test-EnvironmentConfigurationEntity',
    'New-EnvironmentConfigurationEntity',
    'New-EnvironmentConfigurationTableEntry',

    # --- Schema Property Handlers
    'Get-SchemaPropertyValue',
    'Expand-SchemaProperty',

    # --- Storage Account Handlers
    'Set-TableStorageEntity',
    'Get-StorageAccountConnectionString'
)

