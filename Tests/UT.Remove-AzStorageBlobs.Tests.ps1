$Config = Get-Content $PSScriptRoot\..\Tests\Unit.Tests.Config.json -Raw | ConvertFrom-Json
Set-Location $PSScriptRoot\..\Infrastructure-Scripts\

Describe "Remove-AzStorageBlobs Unit Tests" -Tags @("Unit") {

    Context "Resource does not exist" {
        It "The specified Storage Account was not found, throw an error" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName } | Should Throw "Storage container not found"
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
        }
    }

    Context "Resource exists" {
        It "The Remove command should not be called as Dryrun False is not passed in" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return "PesterContainer" }
            Mock Get-AzStorageBlob -MockWith {
                return @(
                    [pscustomobject]@{
                        Name         = 'PesterTest.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "text/plain"
                        LastModified = (Get-Date).AddDays(-2.5)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'TPRFormatFile.fmt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    }
                )
            }
            Mock Remove-AzStorageBlob -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName } | Should Not throw
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzStorageBlob' -Times 0 -Scope It -Exactly
        }
        It "All files should be deleted as no filters passed in" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return "PesterContainer" }
            Mock Get-AzStorageBlob -MockWith {
                return @(
                    [pscustomobject]@{
                        Name         = 'PesterTest.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "text/plain"
                        LastModified = (Get-Date).AddDays(-2.5)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'TPRFormatFile.fmt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    }
                )
            }
            Mock Remove-AzStorageBlob -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName -DryRun $false } | Should Not throw
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzStorageBlob' -Times 2 -Scope It -Exactly
        }
        It "Only the txt file should be deleted as .fmt ignored" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return "PesterContainer" }
            Mock Get-AzStorageBlob -MockWith {
                return @(
                    [pscustomobject]@{
                        Name = 'PesterTest.txt'
                        BlobType = 'BlockBlob'
                        Length = 4
                        ContentType = "text/plain"
                        LastModified = (Get-Date).AddDays(-2.5)
                        IsDeleted = $False
                    },
                    [pscustomobject]@{
                        Name         = 'TPRFormatFile.fmt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    }
                )
            }
            Mock Remove-AzStorageBlob -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName -DryRun $False -FilesToIgnore "*.fmt"} | Should Not throw
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzStorageBlob' -Times 1 -Scope It -Exactly
        }
        It "Only the txt file should be ignored as both .csv and .fmt ignored" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return "PesterContainer" }
            Mock Get-AzStorageBlob -MockWith {
                return @(
                    [pscustomobject]@{
                        Name         = 'PesterTest.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "text/plain"
                        LastModified = (Get-Date).AddDays(-2.5)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'PesterTest2.fmt'
                        BlobType     = 'BlockBlob'
                        Length       = 24
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'PesterTest2.csv'
                        BlobType     = 'BlockBlob'
                        Length       = 24
                        ContentType  = "application/vnd.ms-excel"
                        LastModified = (Get-Date).AddDays(-25)
                        IsDeleted    = $False
                    }
                )
            }
            Mock Remove-AzStorageBlob -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName -DryRun $False -FilesToIgnore "*.csv, *.fmt" } | Should Not throw
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzStorageBlob' -Times 1 -Scope It -Exactly
        }
        It "Only the files older than 7 days should be deleted" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return "PesterContainer" }
            Mock Get-AzStorageBlob -MockWith {
                return @(
                    [pscustomobject]@{
                        Name         = 'PesterTest.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "text/plain"
                        LastModified = (Get-Date).AddDays(-2.5)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'PesterTest2.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 24
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'Pester.csv'
                        BlobType     = 'BlockBlob'
                        Length       = 24
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-12)
                        IsDeleted    = $False
                    }
                )
            }
            Mock Remove-AzStorageBlob -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName -DryRun $False -FilesOlderThan -7 } | Should Not throw
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzStorageBlob' -Times 2 -Scope It -Exactly
        }

        It "Only the files older than 7 days and not .csv should be deleted" {
            Mock New-AzStorageContext -MockWith {
                $StorageContext = [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]::EmptyContextInstance
                return $StorageContext
            }
            Mock Get-AzStorageContainer -MockWith { return "PesterContainer" }
            Mock Get-AzStorageBlob -MockWith {
                return @(
                    [pscustomobject]@{
                        Name         = 'PesterTest.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "text/plain"
                        LastModified = (Get-Date).AddDays(-2.5)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'PesterTest5.csv'
                        BlobType     = 'BlockBlob'
                        Length       = 4
                        ContentType  = "text/plain"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    },
                    [pscustomobject]@{
                        Name         = 'PesterTest2.txt'
                        BlobType     = 'BlockBlob'
                        Length       = 24
                        ContentType  = "application/octet-stream"
                        LastModified = (Get-Date).AddDays(-65)
                        IsDeleted    = $False
                    }
                )
            }
            Mock Remove-AzStorageBlob -MockWith { return $null }
            { ./Remove-AzStorageBlobs -StorageAccount $Config.storageAccountName -SASToken $Config.storageAccountSASToken -StorageContainer $Config.storageContainerName -DryRun $False -FilesOlderThan -7 -FilesToIgnore "*.csv" } | Should Not throw
            Assert-MockCalled -CommandName 'New-AzStorageContext' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Get-AzStorageContainer' -Times 1 -Scope It
            Assert-MockCalled -CommandName 'Remove-AzStorageBlob' -Times 1 -Scope It -Exactly
        }
    }
}
