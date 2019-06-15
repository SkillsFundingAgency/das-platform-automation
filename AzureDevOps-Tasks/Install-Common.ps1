<#
    .DESCRIPTION
    Install common task modules at build time.
#>

Param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileInfo]$TaskRoot,
    [Parameter(Mandatory = $false)]
    [switch]$Clean
)

# --- Initialize package sources
Write-Verbose -Message "Initializing package provider: NuGet"
$null = Find-PackageProvider -Name NuGet | Install-PackageProvider -Force
$null = Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Force

Write-Verbose -Message "Resolving common paths.."
$ResolvedTaskRoot = (Resolve-Path -Path "$TaskRoot").Path
$ConfigPath = "$($ResolvedTaskRoot)/common.json"
Write-Verbose "TaskRoot: $ResolvedTaskRoot"
Write-Verbose "ConfigPath: $ConfigPath"

if (!$ConfigPath) {
    throw "Could not find common.json at $ConfigPath"
}

Write-Verbose "Retrieving config definition from $ConfigPath"
$Config = (Get-Content -Path $ConfigPath -Raw) | ConvertFrom-Json

foreach ($Package in $Config.Include) {
    Write-Verbose "Processing package dependency $($Package.Name)"

    Write-Verbose "Resolving package path"
    [System.IO.FileInfo]$ResolvedPackagePath = "$($ResolvedTaskRoot)/$($Package.Path)"
    Write-Verbose "PackagePath: $ResolvedPackagePath"

    switch ($Package.Type) {
        'PSGallery' {
            Write-Host "[PSGallery] Searching for package $($Package.Name)"
            $Package = Find-Package -Name $Package.Name -Source PSGallery
            if (!$Package) {
                throw "Could not find package with name $($Package.Name)"
            }

            if ($Clean.IsPresent){
                Write-Host "Cleaning package directory: $ResolvedPackagePath"
                Get-ChildItem -Path "$ResolvedPackagePath" -Recurse | Remove-Item -Recurse -Force
            }

            Write-Host "[PSGallery] Installing package $($Package.Name) to $ResolvedPackagePath "
            Save-Module -Name $Package.Name -Path $ResolvedPackagePath -Force

            break
        }
        'Nuget' {
            Write-Host "[NuGet] Searching for package $($Package.Name)"
            $Package = Find-Package -Name "$($Package.Name)" -Source nuget.org -Verbose:$VerbosePreference
            if (!$Package) {
                throw "Could not find package with name $($Package.Name)"
            }

            if ($Clean.IsPresent){
                Write-Host "Cleaning package directory: $ResolvedPackagePath"
                Get-ChildItem -Path $ResolvedPackagePath -Recurse | Remove-Item -Recurse -Force
            }

            Write-Host "[NuGet] Installing package $($Package.Name) to $ResolvedPackagePath"
            Save-Package -Name $Package.Name -ProviderName Nuget -LiteralPath $ResolvedPackagePath -Force

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
}
