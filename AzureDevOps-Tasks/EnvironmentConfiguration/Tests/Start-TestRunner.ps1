# --- Agent properties
$ENV:SYSTEM_CULTURE = "en-US"
$ENV:AGENT_VERSION = "2.152.1"
$ENV:AGENT_PROXYURL = "https://dummy.com"
$ENV:AGENT_PROXYUSERNAME = "dummy"
$ENV:AGENT_PROXYPASSWORD = "dummy"
$ENV:AGENT_PROXYBYPASSLIST = "[]"

# --- Task Entrypoint properties
$SourcePath = "$PSScriptRoot/resource"
$TargetFilename = "*.schema.json"
$TableName = "configuration"
$StorageAccount = "helloitscraigstr"

# --- Custom environment variables
$EnvironmentName = "DEV"

# --- Schema properties
$ENV:EventsApiBaseUrl = "https://events.test.com"
$ENV:EventsApiClientToken = "xxxxxxxxxxlksmdflkm3lkmlkm"
$ENV:PaymentsEnabled = $true
$ENV:PaymentsInt = 1
$ENV:PaymentsNumber = 1.0
$ENV:PaymentsArray = "['one', 'two', 'three']"

$TaskRoot = "$PSScriptRoot\..\task"

# --- Override custom module import
function Global:Trace-VstsEnteringInvocation {}
function Global:Trace-VstsLeavingInvocation {}

. $TaskRoot\Invoke-Task.ps1 -Verbose


