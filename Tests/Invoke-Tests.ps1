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

#Requires -Modules Pester, PSScriptAnalyzer

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Acceptance", "Quality", "Unit")]
    [String] $TestType = "All"
)

$TestParameters = @{
    OutputFormat = 'NUnitXml'
    OutputFile   = "$PSScriptRoot\TEST-$TestType.xml"
    Script       = "$PSScriptRoot"
    PassThru     = $true
}
if ($TestType -ne 'All') {
    $TestParameters['Tag'] = $TestType
}

Remove-Item "$PSScriptRoot\TEST-*.xml"

$Result = Invoke-Pester @TestParameters

if ($Result.FailedCount -ne 0) {
    Write-Error "Pester returned $($Result.FailedCount) errors"
}
