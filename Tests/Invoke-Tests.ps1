<#
.SYNOPSIS
Runner to invoke Acceptance, Quality and / or Unit tests

.DESCRIPTION
Test wrapper that invokes

.PARAMETER TestType
[Optional] The type of test that will be executed. The parameter value can be either All (default), Acceptance, Quality or Unit

.EXAMPLE
Invoke-AcceptanceTests.ps1

.EXAMPLE
Invoke-AcceptanceTests.ps1 -TestType Unit

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "Acceptance", "Quality", "Unit")]
    [String] $TestType = "All"
)

$TestParameters = @{
    OutputFormat = 'NUnitXml'
    OutputFile   = "$PSScriptRoot\TEST-$TestType.xml"
    Script       = "$PSScriptRoot"
    PassThru     = $True
}
if ($TestType -ne 'All') {
    $TestParameters['Tag'] = $TestType
}

# Install required modules
$RequiredModules = @("Pester", "PSScriptAnalyzer")
foreach ($Module in $RequiredModules) {
    if (!(Get-Module -Name $Module -ListAvailable)) {
        Write-Verbose "Installing $Module"
        Install-Module -Name $Module -Scope CurrentUser -Force
    }
}

# Remove previous runs
Remove-Item "$PSScriptRoot\TEST-*.xml"

# Invoke tests
$Result = Invoke-Pester @TestParameters

# report failures
if ($Result.FailedCount -ne 0) {
    Write-Error "Pester returned $($result.FailedCount) errors"
}
