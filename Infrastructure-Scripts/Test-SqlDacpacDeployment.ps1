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
    ##TO DO: change condition back to "PROD"
    #if ($Environment -eq "PROD") {
    if ($Environment -eq "AT") {    
        Write-Verbose "Environment is PROD, checking for approval to override BlockOnPossibleDataLoss"
        try {
            Get-Variable -Name ApproveOverrideBlockOnPossibleDataLoss -ErrorAction Stop
        }
        catch {
            throw "ApproveOverrideBlockOnPossibleDataLoss variable is not set in this pipeline.  See docs for this script for further info."
        }
        if($ApproveOverrideBlockOnPossibleDataLoss) {
            Write-Verbose "Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false'"
        }
        else {
            Write-Verbose "Override for BlockOnPossibleDataLoss not approved, deploying DACPAC with default arguments"
        }
    }
    else {
        Write-Verbose "Environment is not PROD, overriding BlockOnPossibleDataLoss"
    }
}
else {
    Write-Verbose "Override BlockOnPossibleDataLoss not requested"
}

