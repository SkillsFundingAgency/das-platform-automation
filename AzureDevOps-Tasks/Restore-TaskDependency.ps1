<#
    .SYNOPSIS
    Install common task modules at build time.

    .DESCRIPTION
    Install common task modules at build time.

    .PARAMETER TaskRoot
    The root of the task to be built

    .PARAMETER Clean
    Clean package directories before building

    .PARAMETER NoRestore
    Don't restore packages. Can only be used with Clean.

    .EXAMPLE
    Restore-TaskDependency -TaskRoot ./MyTask

    .EXAMPLE
    Restore-TaskDependency -TaskRoot ./MyTask -Clean

    .EXAMPLE
    Restore-TaskDependency -TaskRoot ./MyTask -Clean -NoRestore
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.IO.FileInfo]$TaskRoot,
    [Parameter(Mandatory = $false)]
    [switch]$Clean
)

# Default error action to stop
$ErrorActionPreference = "Stop"

try {
    Write-Verbose -Message "Resolving common paths.."
    $ResolvedTaskRoot = (Resolve-Path -Path "$TaskRoot").Path
    $ConfigPath = "$($ResolvedTaskRoot)/dependency.json"
    $PackageTemp = "$($ENV:Temp)/$((New-Guid).ToString())"
    $null = New-Item -Path $PackageTemp -ItemType Directory -Force
    Write-Verbose -Message "ResolvedTaskRoot: $ResolvedTaskRoot"
    Write-Verbose -Message "ConfigPath: $ConfigPath"

    if (!$ConfigPath) {
        throw "Could not find dependency.json at $ConfigPath"
    }

    Write-Verbose -Message "Retrieving config definition from $ConfigPath"
    $Config = (Get-Content -Path $ConfigPath -Raw) | ConvertFrom-Json

    if ($Clean.IsPresent) {
        Write-Host "Cleaning package directories:"
        $Config.Include | Select-Object -Property Path -Unique | ForEach-Object {
            if ($_.Path) {
                Write-Host " - $($_.Path)"
                Get-ChildItem -Path "$($ResolvedTaskRoot)/$($_.Path)" -Recurse | Remove-Item -Recurse -Force
            }
        }
    }

    foreach ($Package in $Config.Include | Sort-Object -Property Type) {
        Write-Verbose -Message "Processing package dependency $($Package.Name)"
        Write-Verbose -Message "Clean package directories: $($NoResotre.IsPresent)"

        Write-Verbose -Message "Resolving package path"
        [System.IO.FileInfo]$ResolvedPackagePath = "$($ResolvedTaskRoot)/$($Package.Path)"
        Write-Verbose -Message "ResolvedPackagePath: $ResolvedPackagePath"


        switch ($Package.Type) {
            'PSGallery' {

                    $PackageInstallDirectory = "$PackageTemp/$($Package.Name)"

                    $SaveModuleParameters = @{
                        Name            = $Package.Name
                        Path            = $PackageTemp
                        RequiredVersion = $Package.Version
                        Force           = $true
                    }

                    Write-Host "[PSGallery] Saving module $($Package.Name) to $PackageTemp "
                    Save-Module @SaveModuleParameters

                    if ($Package.Copy) {
                        $Package.Copy | ForEach-Object {
                            Write-Host "[PSGallery] Copying module $($Package.Name) to $($Package.Path)"
                            Copy-Item -Path $PackageInstallDirectory/$_ -Destination "$ResolvedPackagePath/$($Package.Name)" -Recurse -Force
                        }
                    }

                break
            }
            'Nuget' {

                    $PackageDestination = "$PackageTemp/$($Package.Name).$($Package.Version)"

                    $InstallPackageParameters = @{
                        Name             = $Package.Name
                        Destination      = $PackageTemp
                        SkipDependencies = $true
                        ForceBootstrap   = $true
                        RequiredVersion  = $Package.Version
                        Force            = $true
                    }

                    Write-Host "[NuGet] Installing package $($Package.Name) to $($PackageTemp)"
                    $null = Install-Package @InstallPackageParameters

                    if ($Package.Copy) {
                        $Package.Copy | ForEach-Object {
                            Write-Host "[NuGet] Copying dependency $_ to $($Package.Path)"
                            Copy-Item -Path $PackageDestination/$_ -Destination $ResolvedPackagePath -Recurse -Force
                        }
                    }

                break
            }
            'GitHub' {
                $RepositoryUrl = "https://github.com/$($Package.Name).git"
                $RepositoryDestination = "$PackageTemp/$($Package.Name.Split("/")[1])"
                Write-Host "[GitHub] Processing $($RepositoryUrl)"
                & git.exe clone $RepositoryUrl $RepositoryDestination

                if ($Package.Copy) {
                    $Package.Copy | ForEach-Object {
                        Write-Host "[GitHub] Copying dependency $_ to $($Package.Path)"
                        Copy-Item -Path $RepositoryDestination/$_ -Destination $ResolvedPackagePath -Recurse -Force
                    }
                }

                break
            }
            'Defaut' {
                throw "Unknown package type: $($Package.Type). Supported package types are [GitHub, NuGet, PowerShellGallery]"
            }
        }
    }
}
catch {
    throw $_
}
finally {
    Write-Verbose -Message "Cleaning temp directory $PackageTemp"
    Remove-Item -Path $PackageTemp -Recurse -Force
}
