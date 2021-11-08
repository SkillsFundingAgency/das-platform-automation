<#
##TO DO: documentation on how to set ApproveOverrideBlockOnPossibleDataLoss variable
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    #[ValidateSet("AT", "TEST", "TEST2", "PP", "PROD", "MO", "DEMO")]
    #[string]
    $Environment,
    [Parameter(Mandatory=$true)]
    #[boolean]
    $OverrideBlockOnPossibleDataLoss
)

Write-Verbose "Checking if BlockOnPossibleDataLoss has been overridden"
if ($OverrideBlockOnPossibleDataLoss) {
    Write-Verbose "Override BlockOnPossibleDataLoss requested"
    if ($Environment -eq "PROD") {
        Write-Verbose "Environment is PROD, checking for approval to override BlockOnPossibleDataLoss"
        try {
            Get-Variable -Name ApproveOverrideBlockOnPossibleDataLoss -ErrorAction Stop
        }
        catch {
            throw "ApproveOverrideBlockOnPossibleDataLoss variable is not set in this pipeline.  See docs for this script for further info."
        }
    }
    else {
        Write-Verbose "Environment is not PROD, overriding BlockOnPossibleDataLoss"
    }
}
else {
    Write-Verbose "Override BlockOnPossibleDataLoss not requested"
}

