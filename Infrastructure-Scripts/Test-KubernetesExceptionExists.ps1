<#
    .SYNOPSIS
    Used within an Azure DevOps pipeline as part of create-kubernetes-exception.yml in das-platform-building-blocks to
    test whether the resource exists in the JSON output of a 'kubectl get crd' command.

    .DESCRIPTION
    The script tests the json object passed as KubectlOutput from a Kubectl task and sets the
    ExceptionExists Azure DevOps variable to true or false depending on if it is found.

    .PARAMETER KubectlOutput
    JSON output from 'kubectl get crd' command.

    .PARAMETER ExceptionName
    Exception name to test for.

    .EXAMPLE
    Test-KubernetesExceptionExists.ps1 -KubectlOutput $(PreviousPipelineTaskName.KubectlOutput) -ExceptionName 'azurepodidentityexceptions.aadpodidentity.k8s.io'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [String]$KubectlOutput,
    [Parameter(Mandatory=$true)]
    [String]$ExceptionName
)

$KubectlObject = ConvertFrom-Json -InputObject $KubectlOutput
$ExceptionSearch = $KubectlObject.items | Where-Object { $_.metadata.name -eq $ExceptionName }
if ($ExceptionSearch) {

    Write-Verbose "Exception $ExceptionName found."
    Write-Output "##vso[task.setvariable variable=ExceptionExists]true"

}
else {

    Write-Verbose "Exception $ExceptionName not found."
    Write-Output "##vso[task.setvariable variable=ExceptionExists]false"

}
