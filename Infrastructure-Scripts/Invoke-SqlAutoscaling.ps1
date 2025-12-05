param(
    [string] $ResourceGroup = (Get-AutomationVariable -Name 'Autoscale_ResourceGroup'),
    [string] $ServerName = (Get-AutomationVariable -Name 'Autoscale_SqlServerName'),
    [string] $DbName = (Get-AutomationVariable -Name 'Autoscale_DbName'),

    [string] $SecondaryServerName = (Get-AutomationVariable -Name 'Autoscale_SecondarySqlServerName'),
    [string] $SecondaryDbName = (Get-AutomationVariable -Name 'Autoscale_SecondaryDbName'),
    [bool]   $HasSecondary = (Get-AutomationVariable -Name 'Autoscale_HasSecondary'),

    [string] $SbResourceGroup = (Get-AutomationVariable -Name 'Autoscale_ResourceGroup'),
    [string] $SbNamespace = (Get-AutomationVariable -Name 'Autoscale_SbNamespace'),
    [string] $SbQueue = (Get-AutomationVariable -Name 'Autoscale_SbQueue'),

    [int] $ScaleUpThreshold = (Get-AutomationVariable -Name 'Autoscale_ScaleUpThreshold'),
    [int] $ScaleDownThreshold = (Get-AutomationVariable -Name 'Autoscale_ScaleDownThreshold'),
    [int] $SustainedUpMinutes = (Get-AutomationVariable -Name 'Autoscale_SustainedUpMinutes'),
    [int] $SustainedDownMinutes = (Get-AutomationVariable -Name 'Autoscale_SustainedDownMinutes'),

    [string] $ScaleUpTarget = (Get-AutomationVariable -Name 'Autoscale_ScaleUpTarget'),
    [string] $ScaleDownTarget = (Get-AutomationVariable -Name 'Autoscale_ScaleDownTarget')
)

function Log($msg) {
    Write-Output ("[{0}] {1}" -f (Get-Date -Format o), $msg)
}

function Test-SustainedMetric {
    param(
        [string] $ResourceId,
        [string] $MetricName,
        [int] $DurationMinutes,
        [double] $Threshold,
        [ValidateSet("GreaterOrEqual", "LessOrEqual")]
        [string] $Comparison
    )

    if ($DurationMinutes -le 0) { return $true }

    $endTime = (Get-Date).ToUniversalTime()
    $startTime = $endTime.AddMinutes(-1 * $DurationMinutes)

    try {
        if ($DurationMinutes -lt 1) {
            $DurationMinutes = 1
            $startTime = $endTime.AddMinutes(-1)
        }

        $metric = Get-AzMetric `
            -ResourceId $ResourceId `
            -MetricName $MetricName `
            -TimeGrain ([TimeSpan]::FromMinutes(1)) `
            -StartTime $startTime `
            -EndTime $endTime `
            -Aggregation Average `
            -WarningAction SilentlyContinue `
            -ErrorAction Stop
        
        if (-not $metric -or -not $metric.Data) {
            Log "Metric $MetricName returned no data."
            return $false
        }

        $points = $metric.Data | Where-Object { $null -ne $_.Average }

        if (-not $points) {
            Log "Metric $MetricName returned no datapoints."
            return $false
        }

        switch ($Comparison) {
            "GreaterOrEqual" {
                return (($points | Where-Object { $_.Average -lt $Threshold }).Count -eq 0)
            }
            "LessOrEqual" {
                return (($points | Where-Object { $_.Average -gt $Threshold }).Count -eq 0)
            }
        }
    }
    catch {
        Log "Failed metric query for $MetricName on resource $ResourceId : $($_.Exception.Message)"
        return $false
    }
}

function Invoke-Scale {
    param(
        [string] $TargetObjective,
        [string] $ResourceGroup,
        [string] $ServerName,
        [string] $DbName
    )

    Log "Requesting new Database Tier '$TargetObjective' for $DbName"
    Set-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $DbName -RequestedServiceObjectiveName $TargetObjective | Out-Null
    Log "Scale operation submitted."
}

function Scale-DatabaseInOrder {
    param(
        [bool]   $IsScaleUp,
        [string] $PrimaryTarget,
        [string] $SecondaryTarget
    )

    if ($HasSecondary -and $SecondaryServerName -and $SecondaryDbName) {

        if ($IsScaleUp) {
            Log "Scaling UP: secondary first → primary second"

            Invoke-Scale -TargetObjective $SecondaryTarget -ResourceGroup $ResourceGroup -ServerName $SecondaryServerName -DbName $SecondaryDbName
            Invoke-Scale -TargetObjective $PrimaryTarget -ResourceGroup $ResourceGroup -ServerName $ServerName -DbName $DbName
        }
        else {
            Log "Scaling DOWN: primary first → secondary second"

            Invoke-Scale -TargetObjective $PrimaryTarget -ResourceGroup $ResourceGroup -ServerName $ServerName -DbName $DbName
            Invoke-Scale -TargetObjective $SecondaryTarget -ResourceGroup $ResourceGroup -ServerName $SecondaryServerName -DbName $SecondaryDbName
        }
    }
    else {
        Log "Single-database environment — normal scaling"

        Invoke-Scale -TargetObjective $PrimaryTarget -ResourceGroup $ResourceGroup -ServerName $ServerName -DbName $DbName
    }
}

Log "Authenticating with managed identity..."
Connect-AzAccount -Identity | Out-Null
Log "Authenticated."

Log "Reading Service Bus queue..."
$queue = Get-AzServiceBusQueue -ResourceGroupName $SbResourceGroup -NamespaceName $SbNamespace -Name $SbQueue
$active = [int]$queue.CountDetails.ActiveMessageCount
Log "Active messages: $active"

Log "Reading current Database Tier..."
$db = Get-AzSqlDatabase -ResourceGroupName $ResourceGroup -ServerName $ServerName -DatabaseName $DbName
$currentObjective = $db.CurrentServiceObjectiveName
Log "Current Database Tier: $currentObjective"

$resourceId = $queue.Id

$shouldScaleUp =
    $active -ge $ScaleUpThreshold -and
    (Test-SustainedMetric -ResourceId $resourceId -MetricName "ActiveMessages" -DurationMinutes $SustainedUpMinutes -Threshold $ScaleUpThreshold -Comparison "GreaterOrEqual")

$shouldScaleDown =
    $active -le $ScaleDownThreshold -and
    (Test-SustainedMetric -ResourceId $resourceId -MetricName "ActiveMessages" -DurationMinutes $SustainedDownMinutes -Threshold $ScaleDownThreshold -Comparison "LessOrEqual")

if ($shouldScaleUp -and $currentObjective -ne $ScaleUpTarget) {
    Log "Scale-up criteria met."
    Scale-DatabaseInOrder -IsScaleUp $true -PrimaryTarget $ScaleUpTarget -SecondaryTarget $ScaleUpTarget
    return
}

if ($shouldScaleDown -and $currentObjective -ne $ScaleDownTarget) {
    Log "Scale-down criteria met."
    Scale-DatabaseInOrder -IsScaleUp $false -PrimaryTarget $ScaleDownTarget -SecondaryTarget $ScaleDownTarget
    return
}

Log "No scaling action required."