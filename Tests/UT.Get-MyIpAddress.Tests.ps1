Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Invoke-RestMethod Unit Tests" -Tags @("Unit") {
    $Params = @{
        WhatsMyIpUrl      = "https://not-a-real-web.com"
    }

    Context "Whats My Ip Service returns a response" {
        Mock Invoke-RestMethod -MockWith { return "1.2.4.5" }
        It "Was able to retrieve the IP Address using https://not-a-real-web.com" {
            { ./Get-MyIpAddress @Params } | Should Not throw
            Assert-MockCalled -CommandName Invoke-RestMethod  -Exactly 1 -Scope It
        }
    }

    Context "Whats My Ip Service fails to get the response" {
        Mock Invoke-RestMethod -MockWith { return "djnfgsgsk%j" }
        It "Was not able to retrieve the IP Address using https://not-a-real-web.com" {
            { ./Get-MyIpAddress @Params } | Should throw "Invalid djnfgsgsk%j"
            Assert-MockCalled -CommandName Invoke-RestMethod  -Exactly 1 -Scope It
        }
    }
}

