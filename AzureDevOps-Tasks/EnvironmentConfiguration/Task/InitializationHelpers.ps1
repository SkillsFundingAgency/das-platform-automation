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

        #--- Explicity import the sdk before other modules
        if (!$ENV:TF_BUILD){
            Import-Module -Name "$PSScriptRoot\ps_modules\VstsTaskSdk\VstsTaskSdk.psd1" -Global
        }

        # --- Hacky, but needed to override a call to this function by the AzureHelpers that is breaking the pipeline
        function Global:Get-VstsWebProxy {
            Write-Output $null
        }

        $null = Get-ChildItem -Path "$PSScriptRoot\ps_modules\" -Directory | Where-Object {$_.Name -ne "VstsTaskSdk"} | ForEach-Object {
            Write-Verbose -Message "Importing Module $($_.Name)"
            Import-Module -Name $_.FullName -Global -Force
        }

    }
    catch {
        throw "Could not initialize task dependencies: $($_.Exception.Message)"
    }
}
