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
    Add-CosmosDBIPException -Name JoeBlogs -IPAddress 192.168.0.1 -ResourceNamePattern das-*

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

try {
    $SubscriptionCosmosDbAccs = Get-AzResource -Name $ResourceNamePattern -ResourceType "Microsoft.DocumentDb/databaseAccounts"

    if (!$SubscriptionCosmosDbAccs) {
        throw "Could not find a resource matching $ResourceNamePattern in the subscription"
    }

    foreach ($CosmosDbAcc in $SubscriptionCosmosDbAccs) {
        # --- Retrieve configuration
        # --- Create or update firewall rules on the Cosmos Db Account
        Write-Output "Processing Cosmos DB Account $($CosmosDbAcc.Name) using -AsJob"
        $CosmosDbIpRules = (Get-AzCosmosDBAccount -ResourceGroupName $CosmosDbAcc.ResourceGroupName -Name $CosmosDbAcc.Name).IpRules.IpAddressOrRangeProperty

        if ($CosmosDbIpRules.length -eq 0) {
            Write-Output "  -> ipRules list is empty for this resource. Skipping."
            continue
        }

        if ($CosmosDbIpRules -notcontains $IPAddress) {
            Write-Output "  -> Adding $($IPAddress) to ipRules ($CosmosDbIpRules -join ','))"
            $NewIPRules = $CosmosDbIpRules + $IPAddress.IPAddressToString
            $null = Update-AzCosmosDBAccount -ResourceGroupName $CosmosDbAcc.ResourceGroupName -Name $CosmosDbAcc.Name -IpRule $NewIPRules -AsJob
        }
        else {
            Write-Output "  -> $IPAddress exists in the current ipRules. Not updating"
        }
    }
    Write-Output "Waiting for Jobs adding Cosmos DB IP exceptions to complete."
    $null = Get-Job | Wait-Job
}
catch {
    throw "Failed to add firewall exception: $_"
}
