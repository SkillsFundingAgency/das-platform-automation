<#
    .DESCRIPTION
    Install common task modules at build time.
#>

Param(
    [Parameter()]
    [String]$TaskRoot
)

# --- Initialize package sources
$null = Find-PackageProvider -Name NuGet | Install-PackageProvider -Force
$null = Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Force

$ResolvedConfigPath = (Resolve-Path -Path "$TaskRoot\common.json" -ErrorAction SilentlyContinue).Path

if (!$ResolvedConfigPath) {
    throw "Could not find common.json at $ConfigPath"
}

$Config = (Get-Content -Path $ResolvedConfigPath -Raw) | ConvertFrom-Json

foreach ($Package in $Config.Include) {

    switch ($Package.Type) {
        'PSGallery' {
            Write-Host "[PSGallery] Searching for package $($Package.Name)"
            $Package = Find-Package -Name $Package.Name -Source PSGallery
            if (!$Package) {
                throw "Could not find package with name $($Package.Name)"
            }

            Write-Host "[PSGallery] Installing package $($Package.Name)"
            $PowerShellModulePath = "$TaskRoot\$($Package.Path)"
            Save-Module -Name $Package.Name -Path $PowerShellModulePath -Force

            break
        }
        'Nuget' {
            Write-Host "[NuGet] Searching for package $($Package.Name)"
            $Package = Find-Package -Name "$($Package.Name)" -Source nuget.org -Verbose:$VerbosePreference
            if (!$Package) {
                throw "Could not find package with name $($Package.Name)"
            }

            Write-Host "[NuGet] Installing package $($Package.Name)"
            Install-Package -Name $Package.Name -ProviderName Nuget -Force

            break
        }
        'Local' {
            # $CommonRoot = "$PSScriptRoot\Common"
            # $ResolvedCommonRoot = (Resolve-Path -Path $CommonRoot).Path

            break
        }
        'Defaut' {
            throw "Unknown package type: $($Package.Type)"
        }
    }

    # $CommonModulePath = "$ResolvedCommonRoot\$Module"
    # if ((Test-Path -Path $CommonModulePath)) {
    #     Write-Host "Adding $Module to $Destination"
    #     Copy-Item -Path $CommonModulePath -Destination $Destination\$Module -Recurse
    # }
    # else {
    #     Write-Error -Message "Could not find $CommonModulePath"
    # }
}
