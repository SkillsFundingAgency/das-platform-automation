$Config = Get-Content $PSScriptRoot\..\Tests\Configuration\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AzSqlIpException Unit Tests" -Tags @("Unit") {

    $env:RELEASE_REQUESTEDFOR = $Config.ruleName
    $Params = @{
        IpAddress           = $Config.ipAddress
        ResourceNamePattern = $Config.resourceName
        Name                = "TestUser"
    }
}

Context "Resource does not exist" {
    It "The specified Resource was not found in the subscription, throw an error" {
        Mock Get-AzResource -MockWith { return $null }
        { ./Remove-AzSqlIpException @Params } | Should throw "Failed to add firewall exception: Could not find a resource matching $($Config.resourceName) in the subscription"
        Assert-MockCalled -CommandName 'Get-AzResource' -Times 1 -Scope It
    }
}


