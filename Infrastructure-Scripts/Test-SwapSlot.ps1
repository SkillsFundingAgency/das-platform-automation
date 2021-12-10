<#
    .SYNOPSIS
    Polls the staging slot URL to test whether the app service has successfully started.

    .DESCRIPTION
    Polls the staging slot URL to test whether the app service has successfully started.

    .PARAMETER WhatsMyIpServiceUrl
    The URL of the service used to obtain the public IP address of the agent running this script.
    Services that can be used include https://ifconfig.me/ip, https://ipapi.co/ip/ and https://api.ipify.org/

    .PARAMETER AppServiceName
    (optional) The name of the app service to be tested, defaults to the environment variable APIAppServiceName

    .PARAMETER ResourceGroupName
    (optional) The name of the app service's resource group, defaults to the environment variable DeploymentResourceGroup

    .PARAMETER SlotName
    (optional) The name of the slot, defaults to staging

    .EXAMPLE
    ./Test-SlotSwap -WhatsMyIpServiceUrl "https://ifconfig.me/ip"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$WhatsMyIpServiceUrl,
    [Parameter(Mandatory=$false)]
    [string]$AppServiceName = "$env:APIAppServiceName",
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "$env:DeploymentResourceGroup",
    [Parameter(Mandatory=$false)]
    [string]$SlotName = "staging"
)

Write-Output "##vso[task.setvariable variable=CompleteSwap]false"

$IpRestrictions = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $ResourceGroupName -Name $AppServiceName -SlotName $SlotName
Write-Verbose "MainSiteAccessRestrictions: `n$($IpRestrictions.MainSiteAccessRestrictions | Format-Table | Out-String)"
$HasIpRestrictions = $IpRestrictions.MainSiteAccessRestrictions.RuleName -notcontains "Allow all" -and ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).IpAddress -notcontains "$MyIp/32"
""
$MyIp = (Invoke-RestMethod $WhatsMyIpServiceUrl -UseBasicParsing)
$IpRegEx = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
if ($MyIp -notmatch $IpRegEx) {
    throw "Unable to retrieve valid IP address using $WhatsMyIpServiceUrl, $MyIp returned."
}

if ($HasIpRestrictions) {
    $Priority = ($IpRestrictions.MainSiteAccessRestrictions | Where-Object { $_.Action -eq "Allow" }).Priority[-1] + 1
    Write-Verbose "Whitelisting $MyIp on app service $AppServiceName with priority $Priority"
    ##TO DO: remove -Verbose, reinstate assign to $null
    <#$null = #>Add-AzWebAppAccessRestrictionRule -ResourceGroupName $ResourceGroupName -WebAppName $AppServiceName -SlotName $SlotName -Name "DeployServer" -IpAddress "$MyIp/32" -Priority $Priority -Action Allow -Verbose
}

$TestUri = "https://$AppServiceName-$SlotName.azurewebsites.net"
$RetryCounter = 1
Write-Verbose "Checking $TestUri for startup errors"
while ($RetryCounter -lt 4) {
    Write-Verbose "Attempt $RetryCounter"
    $503Retries = 10
    for ($i = 0; $i -lt $503Retries; ++$i) {
        try {
            $null = Invoke-WebRequest -Uri $TestUri -UseBasicParsing -TimeoutSec 360
        }
        catch {
            if ($_.Exception.Response.StatusCode.Value__ -eq 503 -and $i + 1 -ne $503Retries) {
                Start-Sleep -Seconds (2+$i)
                continue
            }
            Write-Verbose "Response code $($_.Exception.Response.StatusCode.Value__) received"
            Write-Output $_
            break
        }
    }
    $ErrorResponses = $Errors | Where-Object { $_.ErrorDetails.Message -like "*An error occurred while starting the application.*" `
            -or $_.ErrorDetails.Message -like "*ANCM In-Process Start Failure*" `
            -or $_.Exception.Response.StatusCode.Value__ -ge 500 }
    if ($ErrorResponses) {
        Write-Warning "Staging slot is dead, restarting"
        @($ErrorResponses.Exception.Response.StatusCode.Value__) -join ","
        $null = Restart-AzWebAppSlot -ResourceGroupName $ResourceGroupName -Name $AppServiceName -Slot $SlotName
        Start-Sleep -Seconds 30
        $RetryCounter++
    }
    else {
        Write-Verbose "No app start up errors found, staging slot looks alright, continuing"
        if ($Errors) {
            Write-Warning "Following errors were ignored`n$Errors"
        }
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
2. Go to the Azure portal https://portal.azure.com , logging in with your relevant account.
3. Navigate to the Application Insights resource with the same name as the App Service, by searching in the top search bar.
4. Select the Failures blade.
5. Select the relevant time range for the failed slot swap.
6. Check the Operations/Dependencies/Exceptions tabs.
7. Select the operations in the tabs and drill into the operations to find the reason for the failed slot swap.
8. Share the relevant failed operation/dependency/exception details, including Call Stack if available, with the application team to resolve the exception.
"@
}
