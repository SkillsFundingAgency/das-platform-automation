<#
    .SYNOPSIS
    Ran as part of the sql-dacpac-deploy.yml step.
    Checks whether the BlockOnPossibleDataLoss parameter has been overridden or not - and if PROD, has the required approval.

    .DESCRIPTION
    Ran as part of the sql-dacpac-deploy.yml step.
    Checks whether the BlockOnPossibleDataLoss parameter has been overridden or not.
    If the environment is PROD - Check to make sure approval has been received via built in variable.
    Set variable SetBlockOnPossibleDataLossArgument to true if  approval confimrmed and false if approval not confirmed then set to false.
    If environment is not PROD - no approval is required and the override can take place.
    If environment is not PROD and override is not requested then no action is needed and override of BlockOnPossibleDataLoss does not take place.

    .PARAMETER Environment
    The name of the environtment that the deployment is being run on.

    .PARAMETER OverrideBlockOnPossibleDataLoss
    Boolean value used to distinguish if the BlockOnPossibleDataLoss parameter is attempting to be overridden or not.

    .EXAMPLE
    -Environment AT -OverrideBlockOnPossibleDataLoss $true
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("AT", "TEST", "TEST2", "PP", "PROD", "MO", "DEMO")]
    [string]$Environment,
    [Parameter(Mandatory=$true)]
    [boolean]$OverrideBlockOnPossibleDataLoss
)

Write-Verbose "Checking if BlockOnPossibleDataLoss has been overridden"
if ($OverrideBlockOnPossibleDataLoss) {
    Write-Verbose "Override BlockOnPossibleDataLoss requested"
    if ($Environment -eq "PROD") {    
        Write-Verbose "Environment is PROD, checking for approval to override BlockOnPossibleDataLoss"
        try {
            ##TO DO: decide whether to pass this in as parameter or if direct reference to env var is appropriate
            Get-Variable -Name $ENV:ApproveProdOverrideBlockOnPossibleDataLoss -ErrorAction Stop | Out-Null
        }
        catch {
            throw "ApproveProdOverrideBlockOnPossibleDataLoss variable is not set in this pipeline.  See docs for this script for further info."
        }
        if($ENV:ApproveProdOverrideBlockOnPossibleDataLoss -eq "true") {
            Write-Verbose "Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'"
            Write-Output "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true"
        }
        else {
            Write-Verbose "Override for BlockOnPossibleDataLoss not approved, deploying DACPAC with default arguments"
            Write-Output "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false"
        }
    }
    else {
        Write-Verbose "Environment is not PROD, overriding BlockOnPossibleDataLoss"
    }
}
else {
    Write-Verbose "Override BlockOnPossibleDataLoss not requested"
}
