<#
    .SYNOPSIS
    Update the access restriction rules for a singular or multiple app services.

    .DESCRIPTION
    Update the access restriction rules for a singular or multiple app services.

    .PARAMETER IpAddress
    An ip address to associate with the access restriction rule

    .PARAMETER ResourceNames
    The names of the app services required to be looped through. This can be a singular or multiple app services.

    .PARAMETER RuleName
    The name of the rule being created

    .EXAMPLE
    Add-AppServiceIpException -IpAddress 192.168.0.1 -ResourceNames "das-foobar" -RuleName foobar
    Add-AppServiceIpException -IpAddress 192.168.0.1 -ResourceNames "das-foobar", "das-barfoo" -RuleName foobar
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IpAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String[]]$ResourceNames,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [ValidateLength(1,32)]
    [String]$RuleName
)

foreach ($Resource in $ResourceNames){

    $AppServiceResource = Get-AzResource -Name $Resource -ResourceType "Microsoft.Web/sites"

    if (!$AppServiceResource) {
        throw "Could not find a resource matching $Resource in the subscription"
    }

    $AppServiceResourceConfig = Get-AzWebAppAccessRestrictionConfig -ResourceGroupName $AppServiceResource.ResourceGroupName -Name $Resource
    Write-Output "Processing app service: $Resource ..."

    if ((($AppServiceResourceConfig.MainSiteAccessRestrictions.Count) -gt 1) -and (($AppServiceResourceConfig.MainSiteAccessRestrictions[0].Action) -ne 'Deny')){
        Write-Output "  -> Creating rule: $RuleName"

        # --- Workout next priority number
        $StartPriority = 100
        $ExistingPriority = ($AppServiceResourceConfig.MainSiteAccessRestrictions.priority | Where-Object { ($_ -ge $StartPriority) -and $_ -lt [int32]::MaxValue } | Measure-Object -Maximum).Maximum

        if (!$ExistingPriority) {
            $NewPriority = $StartPriority
        }
        else {
            $NewPriority = $ExistingPriority + 1
        }

        Write-Output "  -> Rule priority set to $NewPriority"
        Add-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResource.ResourceGroupName -WebAppName $Resource -Name $RuleName -Priority $NewPriority -Action "Allow" -IpAddress "$IpAddress/32"
        Write-Output "  -> Rule created successfully."
    }
    elseif (($AppServiceResourceConfig.MainSiteAccessRestrictions[0].Action) -eq 'Deny'){
        Write-Output "  -> Creating rule: $RuleName"

        # --- Workout next priority number
        $StartPriority = $AppServiceResourceConfig.MainSiteAccessRestrictions[0].Priority
        $ExistingPriority = ($AppServiceResourceConfig.MainSiteAccessRestrictions.priority | Where-Object { ($_ -ge $StartPriority) -and $_ -lt [int32]::MaxValue } | Measure-Object -Maximum).Maximum

        if (!$ExistingPriority) {
            $NewPriority = $StartPriority
        }
        else {
            $NewPriority = $ExistingPriority - 1
        }

        Write-Output "  -> Rule priority set to $NewPriority"
        Add-AzWebAppAccessRestrictionRule -ResourceGroupName $AppServiceResource.ResourceGroupName -WebAppName $Resource -Name $RuleName -Priority $NewPriority -Action "Allow" -IpAddress "$IpAddress/32"
        Write-Output "  -> Rule created successfully."
    }
    else{
        Write-Output "  -> There are no existing access restrictions on $Resource. Whitelist is not required."
    }
}
