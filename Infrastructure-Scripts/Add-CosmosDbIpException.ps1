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

        if ($CosmosDbProperties.ipRangeFilter.length -eq 0) {
            Write-Output "  -> ipRestrictions list is empty for this resource. Skipping."
            #continue
        }

        $IPRangeFilterList = [System.Collections.ArrayList]::New($CosmosDbProperties.ipRangeFilter -split ',')

        if ($IPRangeFilterList -notcontains $IpAddress) {
            Write-Output "  -> Adding $($IpAddress) to ipRangeFilter ($($CosmosDbProperties.ipRangeFilter))"
            $null = $IPRangeFilterList.Add($IpAddress.IpAddressToString)
            $CosmosDbProperties.ipRangeFilter = $IPRangeFilterList -join ','
            $null = Set-AzResource -ResourceId $CosmosDbAcc.ResourceId -Properties $CosmosDbProperties -Force
        }
        else {
            Write-Output "  -> $IpAddress exists in the current ipRangeFilter. Not updating"
        }
    }
    Write-Output "Waiting for Jobs to complete."
    $null = Get-Job | Wait-Job
}
catch {
    throw "Failed to add firewall exception: $_"
}
