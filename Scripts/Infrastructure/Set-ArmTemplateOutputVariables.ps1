<#
    .SYNOPSIS
    Takes ARM template output(s) and converts into Azure DevOps variables.

    .DESCRIPTION
    Takes ARM template output(s), usually from the Azure resource group deployment task in Azure DevOps.
    Creates Azure DevOps variables of the same output name so that the values can be used in subsequent pipeline tasks.

    .PARAMETER ArmOutput
    The JSON output from the ARM template to convert into variables.
    If using the  Azure resource group deployment task in an Azure Pipeline, you can set the output to a variable by specifying `Outputs > Deployment outputs`.

    .EXAMPLE
    Set-ArmTemplateOutputVariables.ps1 -ArmOutput '$(ArmOutputs)'
    where ArmOutputs is the name from Outputs > Deployment outputs from the  Azure resource group deployment task
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ArmOutput
)

try {

    # --- Convert the ArmOutput JSON
    try {
        $Outputs = $ArmOutput | ConvertFrom-Json
    }
    catch {
        throw "There was an error, is the 'Deployment output' set in the 'Azure resource group deployment' task?"
    }

    # --- The outputs will be of type noteproperty, get a list of all of them
    foreach ($OutputName in ($Outputs | Get-Member -MemberType NoteProperty).name) {

        # --- Get the type and value for each output
        $OutTypeValue = $Outputs | Select-Object -ExpandProperty $OutputName
        $OutValue = $OutTypeValue.value

        # --- Set Azure DevOps variable(s)
        Write-Output "Setting $OutputName"
        Write-Output "##vso[task.setvariable variable=$OutputName;issecret=true]$OutValue"

    }

    return "Outputs set as pipeline variables successfully."

}

catch {
    throw "$_"
}
