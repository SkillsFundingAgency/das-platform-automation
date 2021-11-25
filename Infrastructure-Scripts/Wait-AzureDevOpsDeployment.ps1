<#
    .SYNOPSIS
    Gets the latest deployment record for a given pipeline and environment and checks whether the current instance is able to run without clashing with said record.

    .DESCRIPTION
    Gets payload from Azure DevOps RestAPI (https://docs.microsoft.com/en-us/rest/api/azure/devops/distributedtask/environmentdeployment-records/list?view=azure-devops-rest-6.0) and filters it to produce the build ID of the newest running build. Then compares to its own build ID, if equal to it then run and if not sleep and redo.

    .PARAMETER EnvironmentId
    The ID number associated with the environemnt stage being used for the deployment.

    .PARAMETER PipelineName
    The name of the pipeline that the deployment is being run on.

    .PARAMETER RunId
    The Run ID of the current deployment which is used to compare to the lowest active RunID returned by the API.

    .PARAMETER SleepTime
    The amount of time in seconds that the process will wait before retrying the comparison if there is another deployment currently running.

    .EXAMPLE
    .\Wait-AzureDevOpsDeployment.ps1 -EnvironmentId 139 -PipelineName das-levy-transfer-matching-api -RunId 459282
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "Known bug - https://github.com/PowerShell/PSScriptAnalyzer/issues/1472")]
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$EnvironmentId,
    [Parameter(Mandatory = $true)]
    [String]$PipelineName,
    [Parameter(Mandatory = $true)]
    [Int]$RunId,
    [Parameter(Mandatory = $false)]
    [Int]$SleepTime = 20,
    [Parameter(Mandatory = $false)]
    [Int]$RetryLimit = 30
)

$Url = "$env:SYSTEM_ORGANISATIONNAME/$env:SYSTEM_PROJECTNAME/_apis/distributedtask/environments/$EnvironmentId/environmentdeploymentrecords?top=100?api-version=6.0-preview.1"
$RetryCounter = 0

while ($RetryCounter -lt $RetryLimit) {
    Write-Verbose "Attempt $RetryCounter"
    try{
        #Invoke call to Azure DevOps Rest API to get all deployment data for given environment.
        $EnvironmentDeployments = Invoke-RestMethod -Method GET -Uri $Url -Headers  @{ Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN" } -TimeoutSec 30
    }
    catch{
        Write-Error "Response code $($_.Exception.Response.StatusCode.Value__) received. Terminating process, deployment will continue."
        Write-Output $_
        break;
    }
    #Filter down results of API call to just contain relevant pipeline runs with matching Pipeline names and only ones that are still running.
    $RunningEnvironmentDeployments = $EnvironmentDeployments.value | Where-Object {$_.definition.name -eq $PipelineName -and -not $_.result}
    $LowestRunId = $RunningEnvironmentDeployments.owner.id | Sort-Object -Top 1
    if ($RunId -eq $LowestRunId) {
        Write-Output("Continuing with deployment.")
        break;
    }
    else {
        $RetryCounter++
        Start-Sleep -Seconds $SleepTime
        Write-Output("There is another deployment to this stage currently running in this environment. Retrying in $SleepTime seconds.")
    }
}
if ($RetryCounter -eq $RetryLimit) {
    Write-Output("Retry limit has been reached - Continuing with deployment.")
}
