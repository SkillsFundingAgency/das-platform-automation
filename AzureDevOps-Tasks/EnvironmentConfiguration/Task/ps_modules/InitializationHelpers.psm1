function Initialize-TaskDependencies {

    try {
        $null = Get-ChildItem -Path "$PSScriptRoot\Lib\*.dll" | ForEach-Object {
            try {
                Write-Verbose -Message "Adding library $($_.Name)"
                Add-Type -Path $_.FullName
            }
            catch [System.Reflection.ReflectionTypeLoadException] {
                Write-Error -Message "Message: $($_.Exception.Message)"
            }
        }

        $null = Get-ChildItem -Path "$PSScriptRoot\Handlers\*.ps1" -File | ForEach-Object {
            Write-Verbose -Message "Adding handler $($_.Name)"
            . $_.FullName
        }
    }
    catch {
        throw "Could not initialize task dependencies: $($_.Exception.Message)"
    }
}
