[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [VariableSet("AT", "TEST", "TEST2", "PP", "PROD", "MO", "DEMO")]
    [string]$Environment,
    [Parameter(Mandatory=$true)]
    [boolean]$OverrideBlockOnPossibleDataLoss
)

Write-Verbose "Checking if BlockOnPossibleDataLoss has been overridden"
if ($OverrideBlockOnPossibleDataLoss) {
    Write-Verbose "Override BlockOnPossibleDataLoss requested"
    if ($Environment -eq "PROD") {
        Write-Verbose "Environment is PROD, checking for approval to override BlockOnPossibleDataLoss"
    }
    else {
        Write-Verbose "Environment is not PROD, overriding BlockOnPossibleDataLoss"
    }
}
else {
    Write-Verbose "Override BlockOnPossibleDataLoss not requested"
}

