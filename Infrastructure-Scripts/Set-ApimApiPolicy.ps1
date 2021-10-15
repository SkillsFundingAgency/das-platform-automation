<#
.SYNOPSIS
Add a policy to an API in an APIM instance

.PARAMETER ApimResourceGroup
The name of the resource group that contains the APIM instance

.PARAMETER InstanceName
The name of the APIM instnace

.PARAMETER ApiName
The ApiId of the API to update.

.PARAMETER ApimApiPolicyFilePath
The full path to the XML file containing the policy to apply to the API

.PARAMETER Version
Specify a version to apply policy to

.PARAMETER LatestVersion
Apply policy to latest API version

#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$ApimResourceGroup,
    [Parameter(Mandatory = $true)]
    [String]$InstanceName,
    [Parameter(Mandatory = $true)]
    [String]$ApiName,
    [Parameter(Mandatory = $true)]
    [String]$ApimApiPolicyFilePath,
    [Parameter(ParameterSetName = "SpecificVersion")]
    [String]$Version,
    [Parameter(ParameterSetName = "LatestVersion")]
    [Switch]$LatestVersion
)

try {

    # --- Build context and retrieve apiid
    Write-Host "Building APIM context for $ApimResourceGroup\$InstanceName"
    $ApimContext = New-AzApiManagementContext -ResourceGroupName $ApimResourceGroup -ServiceName $InstanceName

    # Ensure policy file exists
    Write-Host "Test that policy file exists"
    if (Test-Path -Path $ApimApiPolicyFilePath) {
        Write-Host "Get Api"
        $Apis = Get-AzApiManagementApi -Context $ApimContext -Name $ApiName
        switch ($PSCmdlet.ParameterSetName) {
            "SpecificVersion" {
                $ApiId = ($Apis | Where-Object { $_.ApiVersion -eq $Version }).ApiId
            }
            "LatestVersion" {
                $ApiId = ($Apis | Where-Object { $_.IsCurrent }).ApiId
            }
        }

        Write-Host "Set API policy"
        Set-AzApiManagementPolicy -Context $ApimContext -Format application/vnd.ms-azure-apim.policy.raw+xml -ApiId $ApiId -PolicyFilePath $ApimApiPolicyFilePath -ErrorAction Stop -Verbose:$VerbosePreference
    }
    else {
        throw "Please specify a valid policy file path"
    }
}
catch {
    throw $_
}
