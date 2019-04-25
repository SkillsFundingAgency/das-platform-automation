<#
    .SYNOPSIS
    Runner to invoke Acceptance, Quality and / or Unit tests.

    .DESCRIPTION
    Test wrapper that invokes Acceptance, Quality and / or Unit tests.

    .PARAMETER TestType
    [Optional] The type of test that will be executed. The parameter value can be either All (default), Acceptance, Quality or Unit

    .EXAMPLE
    Invoke-Tests.ps1

    .EXAMPLE
    Invoke-Tests.ps1 -TestType Unit

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Acceptance", "Quality", "Unit")]
    [String] $TestType = "All"
)

$testParameters = @{
    OutputFormat = 'NUnitXml'
    OutputFile   = "$PSScriptRoot\TEST-$TestType.xml"
    Script       = "$PSScriptRoot"
    PassThru     = $True
}
if ($TestType -ne 'All') {
    $testParameters['Tag'] = $TestType
}

$requiredModules = @("Pester", "PSScriptAnalyzer")
foreach ($module in $requiredModules) {
    if (!(Get-Module -Name $module -ListAvailable)) {
        Write-Output "Installing $module"
        Install-Module -Name $module -Scope CurrentUser -Force
    }
}

Remove-Item "$PSScriptRoot\TEST-*.xml"

$result = Invoke-Pester @testParameters

if ($result.FailedCount -ne 0) {
    Write-Error "Pester returned $($result.FailedCount) errors"
}
