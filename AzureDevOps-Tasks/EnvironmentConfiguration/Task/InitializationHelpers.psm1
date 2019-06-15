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

        # --- Explicity import the sdk before other modules
        Import-Module -Name "$PSScriptRoot\ps_modules\VstsTaskSdk\VstsTaskSdk.psd1" -Global -Force

        $null = Get-ChildItem -Path "$PSScriptRoot\ps_modules\" -Directory | Where-Object {$_.Name -ne "VstsTaskSdk"} | ForEach-Object {
            Write-Verbose -Message "Importing Module $($_.Name)"
            Import-Module -Name $_.FullName -Global -Force
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
