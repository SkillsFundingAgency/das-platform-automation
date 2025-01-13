<#
    .SYNOPSIS
    Creates a Grafana annotation for a Grafana Dashboard panel

    .DESCRIPTION
    Uses the Grafana Annotation API to create grafana annotations. Authentication is using Service Account Service token

    .PARAMETER dashboardUID
    The UID of the target Grafana dashboard

    .PARAMETER panelId
    The Id of the panel on the Grafana dashboard

    .PARAMETER tags
    The tags of the annotation

    .PARAMETER text
    The description of the text of the annotation

    .PARAMETER token
    The value of the service account token for authentication

    .EXAMPLE
    .\New-GrafanaDashboardAnnotation.ps1 -dashboardUID "db248fdc-33d2-4579-9f9e-40fd81c92484" -panelId 21 -tags "release-test","101" -text "Release info" -token (ConvertTo-SecureString "xxxxxxxxxx" -AsPlainText -Force)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$dashboardUID,

    [Parameter(Mandatory=$true)]
    [int]$panelId,

    [Parameter(Mandatory=$true)]
    [string[]]$tags,

    [Parameter(Mandatory=$true)]
    [string]$text,

    [Parameter(Mandatory=$true)]
    [securestring]$token
)

# Using function to get current time
function Get-EpochTime {
    $epoch = [int][double]::Parse((Get-Date -UFormat %s))
    return $epoch
}

$tokenPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))

$headers = @{
    "Authorization" = "Bearer $tokenPlain"
    "Content-Type"  = "application/json"
}

#   Using current time
$time = Get-EpochTime

$apiUrl = "https://tools.apprenticeships.education.gov.uk/grafana/api/annotations"

$body = @{
    "dashboardUID" = $dashboardUID
    "panelId"      = $panelId
    "time"         = $time
    "tags"         = $tags
    "text"         = $text
} | ConvertTo-Json

# Create annotation
$response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body

$response
