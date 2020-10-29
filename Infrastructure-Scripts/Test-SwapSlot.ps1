[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$WhatsMyIpServiceUrl = "ifconfig.me/ip",
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "$env:APIAppServiceName",
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "$env:DeploymentResourceGroup",
    [Parameter(Mandatory=$false)]
    [string]$SlotName = "staging"
)

Write-Output "##vso[task.setvariable variable=CompleteSwap]false"

$IpRestrictions = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $AppServiceName -SlotName $SlotName
$HasIpRestrictions = $IpRestrictions.MainSiteAccessRestrictions.RuleName -notcontains "Allow all" -and ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).IpAddress -notcontains "$MyIp/32"

$MyIp = (Invoke-RestMethod $WhatsMyIpServiceUrl -UseBasicParsing)
$IpRegEx = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
if ($MyIp -notmatch $IpRegEx) {
    throw "Unable to retrieve valid IP address using $WhatsMyIpServiceUrl, $MyIp returned."
}

if ($HasIpRestrictions) {
    Write-Verbose "Whitelisting $MyIp"
    $Priority = ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).Priority[-1] + 1
    $null = Add-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName -SlotName $SlotName -Name "DeployServer" -IpAddress "$MyIp/32" -Priority $Priority -Action Allow
}

$TestUri = "https://$AppServiceName-$SlotName.azurewebsites.net"
$RetryCounter = 1
Write-Verbose "Checking $TestUri for startup errors"
while ($RetryCounter -lt 4) {
    Write-Verbose "Attempt $RetryCounter"
    $null = 1..5 | ForEach-Object { Start-ThreadJob -ScriptBlock {
            $503Retries = 10
            for ($i = 0; $i -lt $503Retries; ++$i) {
                try {
                    $null = Invoke-WebRequest -Uri $using:TestUri -UseBasicParsing -TimeoutSec 360
                }
                catch {
                    if ($_.Exception.Response.StatusCode.Value__ -eq 503 -and $i + 1 -ne $503Retries) {
                        Start-Sleep -Seconds (2+$i)
                        continue
                    }
                    Write-Error $_
                    break
                }
            }
        }
    }
    $null = Get-Job | Wait-Job
    $ErrorResponses = Get-Job | Receive-Job | Where-Object { $_.ErrorDetails.Message -like "*An error occurred while starting the application.*" `
            -or $_.ErrorDetails.Message -like "*ANCM In-Process Start Failure*" `
            -or $_.Exception.Response.StatusCode.Value__ -ge 500 }
    if ($ErrorResponses) {
        Get-Job | Remove-Job
        Write-Warning "Staging slot is dead, restarting"
        @($ErrorResponses.Exception.Response.StatusCode.Value__) -join ","
        $null = Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
        Start-Sleep -Seconds 30
        $RetryCounter++
    }
    else {
        Write-Warning "Staging slot looks alright, continuing"
        Write-Output "##vso[task.setvariable variable=CompleteSwap]true"
        break
    }
}

if ($HasIpRestrictions) {
    Write-Verbose "Removing whitelisted IP"
    Remove-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName -SlotName $SlotName -Name "DeployServer"
}

if ($RetryCounter -eq 4) {
    Write-Output "##vso[task.setvariable variable=CompleteSwap]false"
    Write-Output "##vso[task.complete result=Failed;]Staging slot is dead after 3 restarts."
    throw @"
Staging slot is dead after 3 restarts.
1. Check Kibana for the app’s logs during the timeframe of the failed slot swap, the app should log the failed exception. Share the failed exception with the application team. If the failed exception cannot be found, proceed with the following steps.
2. Go to the Azure portal https://portal.azure.com , logging in with your @citizenazuresfabisgov.onmicrosoft.com account if a dev environment, @fcsazuresfabisgov.onmicrosoft.com account if none-dev.
3. Navigate to the Application Insights resource with the same name as the App Service, by searching in the top search bar.
4. Select the Failures blade.
5. Select the relevant time range for the failed slot swap.
6. Check the Operations/Dependencies/Exceptions tabs.
7. Select the operations in the tabs and drill into the operations to find the reason for the failed slot swap.
8. Share the relevant failed operation/dependency/exception details, including Call Stack if available, with the application team to resolve the exception.
"@
}