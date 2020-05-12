<#

    .SYNOPSIS
    Update the firewall of an Cosmos Db Account

    .DESCRIPTION
    Update the firewall of an Cosmos Db Account

    .PARAMETER IPAddress
    An ip address to add to the ip range filter

    .PARAMETER ResourceNamePattern
    Substring of the Cosmos Db Account to search for

    .EXAMPLE
    Add-CosmosDbIPException -IpAddress 192.168.0.1 -ResourceNamePattern das-*

#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [IPAddress]$IpAddress,
    [Parameter(Mandatory = $true)]
    [ValidateNotNull()]
    [String]$ResourceNamePattern
)

try {
    $SubscriptionCosmosDbAccs = Get-AzResource -Name $ResourceNamePattern -ResourceType "Microsoft.DocumentDb/databaseAccounts"

    if (!$SubscriptionCosmosDbAccs) {
        throw "Could not find a resource matching $ResourceNamePattern in the subscription"
    }

    foreach ($CosmosDbAcc in $SubscriptionCosmosDbAccs) {
        # --- Retrieve configuration
        $ServerName = $CosmosDbAcc.Name

        # --- Create or update firewall rules on the Cosmos Db Account
        Write-Output "Processing Cosmos DB Account $ServerName using -AsJob"
        $CosmosDbProperties = (Get-AzResource -ResourceId $CosmosDbAcc.ResourceId).Properties

        if ($CosmosDbProperties.ipRules.length -eq 0) {
            Write-Output "  -> ipRestrictions list is empty for this resource. Skipping."
            continue
        }

        $IPRulesFilterList = [System.Collections.ArrayList]::New($CosmosDbProperties.ipRules -split ',')

        if ($IPRulesFilterList -notcontains $IpAddress) {
            Write-Output "  -> Adding $($IpAddress) to ipRules ($($CosmosDbProperties.ipRules))"
            $null = $IPRulesFilterList.Add($IpAddress.IpAddressToString)
            $CosmosDbProperties.ipRules = $IPRulesFilterList -join ','
            $null = Set-AzResource -ResourceId $CosmosDbAcc.ResourceId -Properties $CosmosDbProperties -Force -AsJob
        }
        else {
            Write-Output "  -> $IpAddress exists in the current ipRules. Not updating"
        }
    }
    Write-Output "Waiting for Jobs to complete."
    $null = Get-Job | Wait-Job
}
catch {
    throw "Failed to add firewall exception: $_"
}
