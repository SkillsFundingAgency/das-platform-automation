<#
    .SYNOPSIS
    Ran as part of the sql-dacpac-deploy.yml step.
    Checks whether the BlockOnPossibleDataLoss parameter has been overridden or not - and if PROD, has the required approval.

    A variable needs to be added to the pipeline via the Azure DevOps GUI to facilitate PROD approvals, see Notes.

    .DESCRIPTION
    Ran as part of the sql-dacpac-deploy.yml step.
    Checks whether the BlockOnPossibleDataLoss parameter has been overridden or not.
    If the environment is PROD - Check to make sure approval has been received via built in variable.
    Set variable SetBlockOnPossibleDataLossArgument to true if approval confirmed and false if approval not confirmed then set to false.
    If environment is not PROD - no approval is required and the override can take place.
    If environment is not PROD and override is not requested then no action is needed and override of BlockOnPossibleDataLoss does not take place.

    .PARAMETER Environment
    The name of the environtment that the deployment is being run on.

    .PARAMETER OverrideBlockOnPossibleDataLoss
    Boolean value used to distinguish if the BlockOnPossibleDataLoss parameter is attempting to be overridden or not.

    .EXAMPLE
    ./Approve-SqlDacpacDeploymentDataLoss -Environment AT -OverrideBlockOnPossibleDataLoss $true

    .NOTES
    To add PROD approval variable:
    1. Navigate to the Pipeline in Azure DevOps and click Edit
    2. Click Variables > New Variable
    3. Set the Variable:
        Name: ApproveProdOverrideBlockOnPossibleDataLoss
        Value: false
        Let users override this value when running this pipeline: ticked
    4. Click Save
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
            Get-Variable -Name $ENV:ApproveProdOverrideBlockOnPossibleDataLoss -ErrorAction Stop | Out-Null
        }
        catch {
            throw "ApproveProdOverrideBlockOnPossibleDataLoss variable is not set in this pipeline.  See docs for this script for further info."
        }
        if($ENV:ApproveProdOverrideBlockOnPossibleDataLoss -eq "true") {
            Write-Output "Override for BlockOnPossibleDataLoss approved, setting AdditionalArgument '/p:BlockOnPossibleDataLoss=false.'"
            Write-Output "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true"
        }
        else {
            Write-Output "Override for BlockOnPossibleDataLoss not approved, deploying DACPAC with default arguments"
            Write-Output "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false"
        }
    }
    else {
        Write-Output "Environment is not PROD, overriding BlockOnPossibleDataLoss"
        Write-Output "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]true"
    }
}
else {
    Write-Output "Override BlockOnPossibleDataLoss not requested"
    Write-Output "##vso[task.setvariable variable=SetBlockOnPossibleDataLossArgument]false"
}
