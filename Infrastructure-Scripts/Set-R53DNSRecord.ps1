#Requires -Modules AWSPowerShell.NetCore

param(
    [Parameter(Mandatory = $true)]
    [String]$DNSRecordName,
    [Parameter(Mandatory = $true)]
    [String]$DNSRecordValue,
    [Parameter(Mandatory = $true)]
    [ValidateSet("A", "CNAME")]
    [String]$RecordType
)

Import-Module AWSPowershell.NetCore

$DNSRecordName = $DNSRecordName.ToLower()
$DNSRecordValue = $DNSRecordValue.ToLower()

$SupportedHostedZones = @(
    "education.gov.uk",
    "manage-apprenticeships.service.gov.uk"
)

$HostedZoneName = $SupportedHostedZones | Where-Object { $DNSRecordName -like "*$_" }

if (!$HostedZoneName) {
    throw "Hosted zone for $DNSRecordName is not supported"
}
if (@($HostedZoneName).Count -gt 1) {
    throw "Multiple hosted zones detected, exiting."
}

$R53HostedZone = Get-R53HostedZones | Where-Object { $_.Name -eq "$HostedZoneName." }

if(!$R53HostedZone){
    throw "Hosted zone $HostedZoneName could not be found in R53"
}

