[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$KubectlOutput,
    [Parameter(Mandatory=$true)]
    [String]$Namespace
)

$KubectlObject = ConvertFrom-Json -InputObject $KubectlOutput
$Namespace = $KubectlObject.items | Where-Object { $_.metadata.name -eq $Namespace }
if ($Namespace) { 
    
    Write-Verbose "Namespace $($Namespace.metadata.name) found."
    Write-Output "##vso[task.setvariable variable=NamespaceExists]true" 

}
else {

    Write-Verbose "Namespace $Namespace not found."
    Write-Output "##vso[task.setvariable variable=NamespaceExists]false" 

}