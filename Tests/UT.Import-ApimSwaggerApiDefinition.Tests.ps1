$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Import-ApimSwaggerApiDefinition Unit Tests" -Tags @("Unit") {

    Context "Could not find APIM Instance" {

        It "The specified APIM Instance was not found in the resource group, throw an error" {
            Mock Get-AzApiManagement -MockWith { Return $null }
            { ./Import-ApimSwaggerApiDefinition -ApimResourceGroup $Config.resourceGroupName -InstanceName $Config.instanceName -AppServiceResourceGroup $Config.resourceGroupName -ApiName $Config.apiName -ApiBaseUrl $Config.apiBaseUrl -ApiPath $Config.apiPath -ApplicationIdentifierUri $Config.applicationIdentifierUri -ProductId $Config.productId } | Should throw "APIM Instance: $($Config.instanceName) does not exist in resource group: $($Config.resourceGroupName)"
            Assert-MockCalled -CommandName 'Get-AzApiManagement' -Times 1 -Scope It
        }

    }

    Context "Could not find Swagger Page" {
        It "Could not find main Swagger Page" {
            Mock Get-AzApiManagement -MockWith { Return "Context" }
            { ./Import-ApimSwaggerApiDefinition -ApimResourceGroup $Config.resourceGroupName -InstanceName $Config.instanceName -AppServiceResourceGroup $Config.resourceGroupName -ApiName $Config.apiName -ApiBaseUrl $Config.apiBaseUrl -ApiPath $Config.apiPath -ApplicationIdentifierUri $Config.applicationIdentifierUri -ProductId $Config.productId} | Should throw "Could not find swagger page at: $($Config.apiBaseUrl)/index.html"
            Assert-MockCalled -CommandName 'Get-AzApiManagement' -Times 1 -Scope It
        }
    }

    Context "APIM Instance exists and found swagger pages - Importing API" {
        It "The specified Resource was not found in the subscription, throw an error" {
            function Read-SwaggerHtml () {}
            function Get-AllSwaggerFilePaths () {}
            Mock Get-AzApiManagement -MockWith { Return "Context" }
            Mock Read-SwaggerHtml -MockWith { Return $null }
            Mock Get-AllSwaggerFilePaths -MockWith { Return @("/swagger/v1/swagger.json", "/swagger/v2/swagger.json") }
            Mock Get-AzApiManagementApiVersionSet -MockWith {
                return @{
                    "Id"          = $Config.resourceId
                    "DisplayName" = $Config.apiName
                }
            }
            Mock Import-AzApiManagementApi -MockWith { Return $null }
            Mock Add-AzApiManagementApiToProduct -MockWith { Return $null }
            Mock Set-AzApiManagementPolicy -MockWith { Return $null }
            { ./Import-ApimSwaggerApiDefinition -ApimResourceGroup $Config.resourceGroupName -InstanceName $Config.instanceName -AppServiceResourceGroup $Config.resourceGroupName -ApiName $Config.apiName -ApiBaseUrl $Config.apiBaseUrl -ApiPath $Config.apiPath -ApplicationIdentifierUri $Config.applicationIdentifierUri -ProductId $Config.productId } | Should not throw
            Assert-MockCalled -CommandName 'Get-AzApiManagement' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Read-SwaggerHtml' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AllSwaggerFilePaths' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzApiManagementApiVersionSet' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Import-AzApiManagementApi' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Add-AzApiManagementApiToProduct' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Set-AzApiManagementPolicy' -Times 1 -Scope It
        }

    }

}
