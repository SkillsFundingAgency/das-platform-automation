<#

    .SYNOPSIS
    Update the firewall of an Search Service

    .DESCRIPTION
    Update the firewall of an Search Service

    .PARAMETER IPAddress
    An ip address to add to the ip range filter

    .PARAMETER ResourceNamePattern
    Substring of the Search Service to search for

    .EXAMPLE
    .\Add-SearchServiceIpException.ps1 -IPAddress 192.168.0.1 -ResourceNamePattern das-

#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IPAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ResourceNamePattern
)

Install-Module Az.Search -Force

try {
    $SubscriptionSearchSvcs = Get-AzResource -ODataQuery "substringof(Name, '$($ResourceNamePattern)') and ResourceType eq 'Microsoft.Search/searchServices'"

    if (!$SubscriptionSearchSvcs) {
        throw "Could not find a resource matching $ResourceNamePattern in the subscription"
    }

    foreach ($SearchSvc in $SubscriptionSearchSvcs) {
        # --- Retrieve configuration
        # --- Create or update firewall rules on the Search Service Account
        Write-Output "Processing Search Service $($SearchSvc.Name) using -AsJob"
        $SearchSvcProperties = (Get-AzResource -ResourceId $SearchSvc.ResourceId -ApiVersion "2023-11-01").Properties
        $SearchSvcIpRules = $SearchSvcProperties.networkRuleSet.IpRules.Value

        if ($SearchSvcIpRules.length -eq 0) {
            Write-Output "  -> ipRules list is empty for this resource. Skipping."
            continue
        }

        if ($SearchSvcIpRules -notcontains $IPAddress) {
            Write-Output "  -> Adding $($IPAddress) to ipRules ($SearchSvcIpRules -join ','))"
            $NewIPRules = $SearchSvcIpRules + $IPAddress.IPAddressToString
            $null = Set-AzSearchService -ResourceGroupName $SearchSvc.ResourceGroupName -Name $SearchSvc.Name -IpRule $NewIPRules
        }
        else {
            Write-Output "  -> $IPAddress exists in the current ipRules. Not updating"
        }
    }
    Write-Output "Waiting for Jobs adding Search Service IP exceptions to complete."
    $null = Get-Job | Wait-Job
}
catch {
    throw "Failed to add firewall exception: $_"
}
