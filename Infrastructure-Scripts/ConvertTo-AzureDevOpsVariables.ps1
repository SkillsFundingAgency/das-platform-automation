<#
.SYNOPSIS
Takes ARM template output and turns them into Azure DevOps variables

.DESCRIPTION
Takes the ARM template output (usually from the Azure Deployment task in Azure DevOps) and creates Azure DevOps variables of the same name with the values so they can be used in subsequent tasks.

.PARAMETER ARMOutput
The JSON output from the ARM template to convert into variables.
If using the Azure Deployment task in an Azure Pipeline, you can set the output to a variable by specifying a deploymentOutputs value

.PARAMETER Rename
[Optional] Allows you to create a AzureDevOps variable with a different name to the output name.
Takes a dictionary where the key is the name of the ARM template output and the value is the desired name of the AzureDevOps variable.
This variable must be wrapped in single quotes when passing to this parameter in an Azure DevOps task.

.EXAMPLE
ConvertTo-AzureDevOpsVariables.ps1 -ARMOutput '$(ARMOutput)'
where ARMOutputs is the deploymentOutputs value from the Azure Deployment task. Note that $(ARMOutput) is wrapped in single quotes.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$ARMOutput,
    [Parameter(Mandatory=$false)]
    [hashtable]$Rename
)

# Output from ARM template is a JSON document
try {
    $JsonVars = $ARMOutput | ConvertFrom-Json
}
catch {
    Write-Verbose "Unable to convert ARMOutput to JSON:`n$ARMOutput"
    throw "Unable to convert ARMOutput to JSON.  Add System.Debug switch to view ARMOutput."
}

# The outputs will be of type NoteProperty, get a list of all of them
foreach ($OutputName in ($JsonVars | Get-Member -MemberType NoteProperty).name) {
    # Get the type and value for each output
    $OutputTypeValue = $JsonVars | Select-Object -ExpandProperty $OutputName
    $OutputType = $OutputTypeValue.type
    $OutputValue = $OutputTypeValue.value

    # Check if variable name needs renaming
    if ($OutputName -in $Rename.keys) {
        $OldName = $OutputName
        $OutputName = $Rename[$OutputName]
        Write-Output "Creating Azure DevOps variable $OutputName from $OldName"
    }
    else {
        Write-Output "Creating Azure DevOps variable $OutputName"
    }

    # Set Azure DevOps variable
    if ($OutputType.toLower() -eq 'securestring') {
        Write-Output "##vso[task.setvariable variable=$OutputName;issecret=true;isOutput=true]$OutputValue"
    }
    else {
        Write-Output "##vso[task.setvariable variable=$OutputName;isOutput=true]$OutputValue"
    }
}
