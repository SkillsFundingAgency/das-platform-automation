<#
    .SYNOPSIS
    Publish an Azure Cloud Service Deployment

    .DESCRIPTION
    Publish an Azure Cloud Service Deployment

    .PARAMETER ServiceName
    The name of the Cloud Service

    .PARAMETER ServiceLocation
    The location of the Cloud Service

    .PARAMETER ClassicStorageAccountName
    The name of the Classic Storage Account used for Set-AzureSubscription and storage of diagnostics

    .PARAMETER ServicePackageFile
    The path of the Cloud Service .CsPkg file

    .PARAMETER ServiceConfigFile
    The path of the Cloud Service .CsCfg file

    .PARAMETER Slot
    Name of Slot for Cloud Service Deployment - Production or Staging

    .EXAMPLE
    ./Publish-AzureCloudServiceDeployment.ps1 -ServiceName das-at-foobar-cs -ServiceLocation foobar -ClassicStorageAccountName dasatfoobarstr -ServicePackageFile ./SFA.DAS.FooBar.CloudService.cspkg -ServiceConfigFile ./ServiceConfiguration.Cloud.cscfg -Slot Production
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$ServiceName,
    [Parameter(Mandatory = $true)]
    [String]$ServiceLocation,
    [Parameter(Mandatory = $true)]
    [String]$ClassicStorageAccountName,
    [Parameter(Mandatory = $true)]
    [String]$ServicePackageFile,
    [Parameter(Mandatory = $true)]
    [String]$ServiceConfigFile,
    [Parameter(Mandatory = $true)]
    [ValidateSet("Production", "Staging")]
    [String]$Slot
)
try {

    function Get-DiagnosticsExtensions($storageAccount, $extensionsPath, $storageAccountKeysMap, [switch]$useArmStorage) {
        $diagnosticsConfigurations = @()
        
        $extensionsSearchPath = Split-Path -Parent $extensionsPath
        Write-Verbose "extensionsSearchPath= $extensionsSearchPath"
        $extensionsSearchPath = Join-Path -Path $extensionsSearchPath -ChildPath "Extensions"
        Write-Verbose "extensionsSearchPath= $extensionsSearchPath"
        #$extensionsSearchPath like C:\Agent\_work\bd5f89a2\staging\Extensions
        if (!(Test-Path $extensionsSearchPath)) {
            Write-Verbose "No Azure Cloud Extensions found at '$extensionsSearchPath'"
        }
        else {
            Write-Host ("Applyinganyconfigureddiagnosticsextensions")

            Write-Verbose "Getting the primary AzureStorageKey..."
            $primaryStorageKey = Get-AzureStoragePrimaryKey $StorageAccount $useArmStorage.IsPresent

            if ($primaryStorageKey) {

                Write-Verbose "##[command]Get-ChildItem -Path $extensionsSearchPath -Filter PaaSDiagnostics.*.PubConfig.xml"
                $diagnosticsExtensions = Get-ChildItem -Path $extensionsSearchPath -Filter "PaaSDiagnostics.*.PubConfig.xml"

                #$extPath like PaaSDiagnostics.WebRole1.PubConfig.xml
                foreach ($extPath in $diagnosticsExtensions) {
                    $role = Get-RoleName $extPath
                    if ($role) {
                        $fullExtPath = Join-Path -path $extensionsSearchPath -ChildPath $extPath
                        Write-Verbose "fullExtPath= $fullExtPath"

                        Write-Verbose "Loading $fullExtPath as XML..."
                        $publicConfig = New-Object XML
                        $publicConfig.Load($fullExtPath)
                        if ($publicConfig.PublicConfig.StorageAccount) {
                            #We found a StorageAccount in the role's diagnostics configuration.  Use it.
                            $publicConfigStorageAccountName = $publicConfig.PublicConfig.StorageAccount
                            Write-Verbose "Found PublicConfig.StorageAccount= '$publicConfigStorageAccountName'"

                            if ($storageAccountKeysMap.containsKey($role)) {
                                Write-Verbose "##Getting diagnostics storage account name and key from passed as storage keys."

                                Write-Verbose "##$storageAccountName = $publicConfigStorageAccountName"
                                $storageAccountName = $publicConfigStorageAccountName
                                $storageAccountKey = $storageAccountKeysMap.Get_Item($role)
                            }
                            else {
                                try {
                                    $publicConfigStorageKey = Get-AzureStoragePrimaryKey $publicConfigStorageAccountName $useArmStorage.IsPresent
                                }
                                catch {   
                                    Write-Host ("Unabletofind0usingprovidedsubscription: $publicConfigStorageAccountName")
                                    Write-Verbose $_.Exception.Message
                                }
                                if ($publicConfigStorageKey) {
                                    Write-Verbose "##Getting storage account name and key from diagnostics config file"

                                    Write-Verbose "##$storageAccountName = $publicConfigStorageAccountName"
                                    $storageAccountName = $publicConfigStorageAccountName
                                    $storageAccountKey = $publicConfigStorageKey
                                }
                                else {
                                    Write-Warning ("Couldnotgettheprimarystoragekeyforthepublicconfigstorageaccount0Unabletoapplyanydiagnosticsextensions: $publicConfigStorageAccountName")
                                    return
                                }
                            }
                        }
                        else {
                            #If we don't find a StorageAccount in the XML file, use the one associated with the definition's storage account
                            Write-Verbose "No StorageAccount found in PublicConfig.  Using the storage account set on the definition..."
                            $storageAccountName = $storageAccount
                            $storageAccountKey = $primaryStorageKey
                        }

                        if ((CmdletHasMember "StorageAccountName") -and (CmdletHasMember "StorageAccountKey")) {
                            Write-Host "New-AzureServiceDiagnosticsExtensionConfig -Role $role -StorageAccountName $storageAccountName -StorageAccountKey <storageKey> -DiagnosticsConfigurationPath $fullExtPath"
                            $wadconfig = New-AzureServiceDiagnosticsExtensionConfig -Role $role -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey -DiagnosticsConfigurationPath $fullExtPath
                        }
                        else {
                            try {
                                $storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
                                Write-Host "New-AzureServiceDiagnosticsExtensionConfig -Role $role -StorageContext $StorageContext -DiagnosticsConfigurationPath $fullExtPath"
                                $wadconfig = New-AzureServiceDiagnosticsExtensionConfig -Role $role -StorageContext $StorageContext -DiagnosticsConfigurationPath $fullExtPath
                            }
                            catch {
                                Write-Warning ("Currentversionofazurepowershelldontsupportexternalstorageaccountforconfiguringdiagnostics")
                                throw $_.Exception
                            }
                        }

                        #Add each extension configuration to the array for use by caller
                        $diagnosticsConfigurations += $wadconfig
                    }
                }
            }
            else {
                Write-Warning ("Couldnotgettheprimarystoragekeyforstorageaccount0Unabletoapplyanydiagnosticsextensions: $storageAccount")
            }
        }
        return $diagnosticsConfigurations
    }

    $label = $ENV:BUILD_BUILDNUMBER
    $storageAccountKeysMap = @{}

    # Set Azure subscription object so there is a CurrentStorageAccountName property
    $subscription = Get-AzureSubscription
    Set-AzureSubscription -CurrentStorageAccountName $ClassicStorageAccountName -SubscriptionId $subscription.SubscriptionId

    Write-Host "##[command]Get-AzureService -ServiceName $ServiceName -ErrorAction SilentlyContinue -ErrorVariable azureServiceError"
    $azureService = Get-AzureService -ServiceName $ServiceName -ErrorAction SilentlyContinue -ErrorVariable azureServiceError

    if ($azureServiceError) {
        $azureServiceError | ForEach-Object { Write-Verbose $_.Exception.ToString() }
    }

    if (!$azureService) {
        $azureService = "New-AzureService -ServiceName `"$ServiceName`""
        $azureService += " -Location `"$ServiceLocation`""
        Write-Host "$azureService"
        $azureService = Invoke-Expression -Command $azureService
    }

    $diagnosticExtensions = Get-DiagnosticsExtensions $ClassicStorageAccountName $ServiceConfigFile $storageAccountKeysMap

    Write-Host "##[command]Get-AzureDeployment -ServiceName $ServiceName -Slot $Slot -ErrorAction SilentlyContinue -ErrorVariable azureDeploymentError"
    $azureDeployment = Get-AzureDeployment -ServiceName $ServiceName -Slot $Slot -ErrorAction SilentlyContinue -ErrorVariable azureDeploymentError

    if ($azureDeploymentError) {
        $azureDeploymentError | ForEach-Object { Write-Verbose $_.Exception.ToString() }
    }

    if (!$azureDeployment) {
        Write-Host "##[command]New-AzureDeployment -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $label -ExtensionConfiguration <extensions>"
        $azureDeployment = New-AzureDeployment -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $label -ExtensionConfiguration $diagnosticExtensions

    }
    else {
        #Use -Upgrade
        Write-Host "##[command]Set-AzureDeployment -Upgrade -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $label -ExtensionConfiguration <extensions>"
        $azureDeployment = Set-AzureDeployment -Upgrade -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $label -ExtensionConfiguration $diagnosticExtensions
    }
}
catch {
    throw "$_"
}
