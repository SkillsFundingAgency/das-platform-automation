# Login to Azure
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

$results = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {

    # Set the context to the subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Get all SQL servers in the subscription
    $sqlServers = Get-AzSqlServer

    foreach ($sqlServer in $sqlServers) {

        # Get all databases in the server
        $databases = Get-AzSqlDatabase -ServerName $sqlServer.ServerName -ResourceGroupName $sqlServer.ResourceGroupName

        foreach ($database in $databases) {

            # Get database size - Max storage size
            $dbMaxSizeByte = $(Get-AzSqlDatabase -DatabaseName $database.DatabaseName -ServerName $sqlServer.ServerName -ResourceGroupName $sqlServer.ResourceGroupName | Select-Object -ExpandProperty MaxSizeBytes)
            $dbMaxSizeGB = $dbMaxSizeByte/1GB
            $dbMaxSizeGB  = "$dbMaxSizeGB" + "GB"

            # Get database size - Used storage size
            $dbMetricStorage = $database | Get-AzMetric -MetricName 'storage'
            $dbUsedSpace = $dbMetricStorage.Data.Maximum | Select-Object -Last 1
            if ($dbUsedSpace -lt 1GB) {
                $dbUsedSpace = [math]::Round($dbUsedSpace / 1MB, 2)
                $dbUsedSpace = "$dbUsedSpace" + "MB"
            }
            else {
                $dbUsedSpace = [math]::Round($dbUsedSpace / 1GB, 2)
                $dbUsedSpace = "$dbUsedSpace" + "GB"
            }
        
            # Get database size - Used space percentage
            $dbUsedSpacePercentage = [math]::Round((($dbMetricStorage.Data.Maximum | Select-Object -Last 1)/$dbMaxSizeByte)*100, 2)
            $dbUsedSpacePercentage  = "$dbUsedSpacePercentage" + "%"

            # Get DTU consumption
            $dtuDetails = $database | Select-Object -ExpandProperty CurrentServiceObjectiveName

            Write-Host "Processing Database $($sqlServer.ServerName)/$($database.DatabaseName)"
            # Add details to results
            $results += [PSCustomObject]@{
                SubscriptionId = $subscription.Id
                SubscriptionName = $subscription.Name
                ServerName = $sqlServer.ServerName
                DatabaseName = $database.DatabaseName
                MaxSizeGB = $dbMaxSizeGB
                UsedSpace = $dbUsedSpace
                UsedSpacePercentage = $dbUsedSpacePercentage
                DTUModel = $dtuDetails
            }
        }
    }
}

# Export results to CSV
$results | Export-Csv -Path "AzureSqlDatabasesReport.csv" -NoTypeInformation

Write-Host "Report Created: AzureSqlDatabasesReport.csv"
