<#
    .SYNOPSIS
    Used within an Azure DevOps pipeline as part of create-kubernetes-namespace.yml in das-platform-building-blocks to
    test whether the namespace exists in the JSON output of a 'kubectl get namespace' command.

    .DESCRIPTION
    The script tests the json object passed as PreviousPipelineTaskName.KubectlOutput from a Kubectl task and sets the
    NamespaceExists Azure DevOps variable to true or false depending on if it is found.

    .PARAMETER KubectlOutput
    JSON output from 'kubectl get namespace' command.

    .PARAMETER Namespace
    Namespace to test for.

    .EXAMPLE
    Test-KubernetesNamespaceExists.ps1 -KubectlOutput $(PreviousPipelineTaskName.KubectlOutput) -Namespace engineering
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$KubectlOutput,
    [Parameter(Mandatory=$true)]
    [String]$Namespace
)

$KubectlObject = ConvertFrom-Json -InputObject $KubectlOutput
$NamespaceSearch = $KubectlObject.items | Where-Object { $_.metadata.name -eq $Namespace }
if ($NamespaceSearch) {

    Write-Verbose "Namespace $Namespace found."
    Write-Output "##vso[task.setvariable variable=NamespaceExists]true"

}
else {

    Write-Verbose "Namespace $Namespace not found."
    Write-Output "##vso[task.setvariable variable=NamespaceExists]false"

}
