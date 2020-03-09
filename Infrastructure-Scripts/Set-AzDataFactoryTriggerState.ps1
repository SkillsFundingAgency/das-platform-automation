<#

    .SYNOPSIS
    Disables or Enables Or Triggers associated with a Data Factory

    .DESCRIPTION
    Disables or Enables Or Triggers associated with a Data Factory Allowing for Safe Release

    .PARAMETER DataFactoryName
    The Name of the Data Factory to run the command against

    .PARAMETER ResourceGroupName
    The Name of the Resource Group hosting the Data Factory.

    .PARAMETER TriggerState
    The State in which to set the triggers either enable or disabled

    .EXAMPLE
    Set-AzDataFactoryTriggerStae -DataFactoryName aDataFactory -ResourceGroupName aResourceGroup -TriggerState disable
    Set-AzDataFactoryTriggerStae -DataFactoryName aDataFactory -ResourceGroupName aResourceGroup -TriggerState enable

#>
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$DataFactoryName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [ValidateSet("enable", "disable")]
    [String]$TriggerState
)

try {
    $ResourceGroupExists = Get-AzResourceGroup $ResourceGroupName
    if (!$ResourceGroupExists) {
        throw "Resource Group $ResourceGroupName does not exist."
    }

    $DataFactoryExists = Get-AzDataFactoryV2 -ResourceGroupName $ResourceGroupName -Name $DataFactoryName
    if (!$DataFactoryExists) {
        throw "The Data Factory $DataFactoryName in Resource Group $ResourceGroupName Does not exists."
    }

    $Triggers = Get-AzDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName  $ResourceGroupName
    if (!$Triggers) {
        throw "No Triggers Associated with $DataFactoryName"
    }

    switch ($TriggerState) {
        "enable" {
            foreach ($Trigger in $Triggers) {
                Start-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $Trigger.name -Force
            }
            break
        }
        "disable" {
            foreach ($Trigger in $Triggers) {
                Stop-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $Trigger.name -Force
            }
            break
        }
    }
}

catch {
    throw "$_"
}
