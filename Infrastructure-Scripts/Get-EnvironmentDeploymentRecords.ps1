[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [String]$Organisation,
    [Parameter(Mandatory = $true)]
    [String]$Project,
    [Parameter(Mandatory = $true)]
    [String]$EnvironmentId,
    [Parameter(Mandatory = $true)]
    [String]$PipelineName,
    [Parameter(Mandatory = $true)]
    [Int]$RunId,
    [Parameter(Mandatory = $true)]
    [String]$AccessToken,
    [Parameter(Mandatory = $false)]
    [Int]$SleepTime = 20
)

$Url = "https://dev.azure.com/$Organisation/$Project/_apis/distributedtask/environments/$EnvironmentId/environmentdeploymentrecords?top=100?api-version=6.0-preview.1"
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($AccessToken)"))
$header = @{authorization = "Basic $token"}

while ($true){
    #Invoke call to Azure DevOps Rest API to get all build data for given environment.
    $EnvironmentPipelineRuns = (Invoke-RestMethod -Method GET -Uri $Url -Headers $header).value
    #Filter down results of API call to just contain relevant pipeline runs with matching Pipeline names and only ones that are still running.
    $RunningEnvironmentPipelineRuns = $EnvironmentPipelineRuns.value | where-object {$_.definition.name -eq $pipelineName -and -not $_.result}
    #$RunningEnvironmentPipelineRuns = $EnvironmentPipelineRuns | where-object {$_.definition.name -eq $pipelineName -and $_.result}
    $LowestRunId = ($RunningEnvironmentPipelineRuns.owner.id | Sort-Object)[0]
    if ($runid -eq $LowestRunId) {
        Write-Host("Continuing with deployment.")
        break;
    }
    else {
        Start-Sleep -s $SleepTime
        Write-Host("There is another deployment to this stage is currently running in this environment. Retrying in $SleepTime seconds")
    }
}



