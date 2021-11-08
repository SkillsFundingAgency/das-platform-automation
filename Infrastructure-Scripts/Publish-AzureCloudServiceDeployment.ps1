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
    function Get-DiagnosticsExtension {
        param(
        [Parameter(Mandatory = $true)]
        [string]$StorageAccount,
        [Parameter(Mandatory = $true)]
        [string]$ExtensionsPath,
        [Parameter(Mandatory = $true)]
        [string]$StorageAccountKeysMap,
        [Parameter(Mandatory = $false)]
        [switch]$UseArmStorage
    )
        $DiagnosticsConfigurations = @()
        $ExtensionsSearchPath = Split-Path -Parent $ExtensionsPath
        Write-Verbose "extensionsSearchPath= $ExtensionsSearchPath"
        $ExtensionsSearchPath = Join-Path -Path $ExtensionsSearchPath -ChildPath "Extensions"
        Write-Verbose "extensionsSearchPath= $ExtensionsSearchPath"
        #$ExtensionsSearchPath like C:\Agent\_work\bd5f89a2\staging\Extensions
        if (!(Test-Path $ExtensionsSearchPath)) {
            Write-Verbose "No Azure Cloud Extensions found at '$ExtensionsSearchPath'"
        }
        else {
            Write-Host ("Applyinganyconfigureddiagnosticsextensions")

            Write-Verbose "Getting the primary AzureStorageKey..."
            $PrimaryStorageKey = Get-AzureStoragePrimaryKey $StorageAccount $useArmStorage.IsPresent

            if ($PrimaryStorageKey) {

                Write-Verbose "##[command]Get-ChildItem -Path $ExtensionsSearchPath -Filter PaaSDiagnostics.*.PubConfig.xml"
                $DiagnosticsExtensions = Get-ChildItem -Path $ExtensionsSearchPath -Filter "PaaSDiagnostics.*.PubConfig.xml"

                #$ExtPath like PaaSDiagnostics.WebRole1.PubConfig.xml
                foreach ($ExtPath in $DiagnosticsExtensions) {
                    $Role = Get-RoleName $ExtPath
                    if ($Role) {
                        $FullExtPath = Join-Path -path $ExtensionsSearchPath -ChildPath $ExtPath
                        Write-Verbose "fullExtPath= $FullExtPath"

                        Write-Verbose "Loading $FullExtPath as XML..."
                        $PublicConfig = New-Object XML
                        $PublicConfig.Load($FullExtPath)
                        if ($PublicConfig.PublicConfig.StorageAccount) {
                            #We found a StorageAccount in the role's diagnostics configuration.  Use it.
                            $PublicConfigStorageAccountName = $PublicConfig.PublicConfig.StorageAccount
                            Write-Verbose "Found PublicConfig.StorageAccount= '$PublicConfigStorageAccountName'"

                            if ($StorageAccountKeysMap.containsKey($Role)) {
                                Write-Verbose "##Getting diagnostics storage account name and key from passed as storage keys."

                                Write-Verbose "##$StorageAccountName = $PublicConfigStorageAccountName"
                                $StorageAccountName = $PublicConfigStorageAccountName
                                $StorageAccountKey = $StorageAccountKeysMap.Get_Item($Role)
                            }
                            else {
                                try {
                                    $PublicConfigStorageKey = Get-AzureStoragePrimaryKey $PublicConfigStorageAccountName $useArmStorage.IsPresent
                                }
                                catch {
                                    Write-Host ("Unabletofind0usingprovidedsubscription: $PublicConfigStorageAccountName")
                                    Write-Verbose $_.Exception.Message
                                }
                                if ($PublicConfigStorageKey) {
                                    Write-Verbose "##Getting storage account name and key from diagnostics config file"

                                    Write-Verbose "##$StorageAccountName = $PublicConfigStorageAccountName"
                                    $StorageAccountName = $PublicConfigStorageAccountName
                                    $StorageAccountKey = $PublicConfigStorageKey
                                }
                                else {
                                    Write-Warning ("Couldnotgettheprimarystoragekeyforthepublicconfigstorageaccount0Unabletoapplyanydiagnosticsextensions: $PublicConfigStorageAccountName")
                                    return
                                }
                            }
                        }
                        else {
                            #If we don't find a StorageAccount in the XML file, use the one associated with the definition's storage account
                            Write-Verbose "No StorageAccount found in PublicConfig.  Using the storage account set on the definition..."
                            $StorageAccountName = $StorageAccount
                            $StorageAccountKey = $PrimaryStorageKey
                        }

                        if ((CmdletHasMember "StorageAccountName") -and (CmdletHasMember "StorageAccountKey")) {
                            Write-Host "New-AzureServiceDiagnosticsExtensionConfig -Role $Role -StorageAccountName $StorageAccountName -StorageAccountKey <storageKey> -DiagnosticsConfigurationPath $FullExtPath"
                            $Wadconfig = New-AzureServiceDiagnosticsExtensionConfig -Role $Role -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey -DiagnosticsConfigurationPath $FullExtPath
                        }
                        else {
                            try {
                                $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
                                Write-Host "New-AzureServiceDiagnosticsExtensionConfig -Role $Role -StorageContext $StorageContext -DiagnosticsConfigurationPath $FullExtPath"
                                $Wadconfig = New-AzureServiceDiagnosticsExtensionConfig -Role $Role -StorageContext $StorageContext -DiagnosticsConfigurationPath $FullExtPath
                            }
                            catch {
                                Write-Warning ("Currentversionofazurepowershelldontsupportexternalstorageaccountforconfiguringdiagnostics")
                                throw $_.Exception
                            }
                        }

                        #Add each extension configuration to the array for use by caller
                        $DiagnosticsConfigurations += $Wadconfig
                    }
                }
            }
            else {
                Write-Warning ("Couldnotgettheprimarystoragekeyforstorageaccount0Unabletoapplyanydiagnosticsextensions: $StorageAccount")
            }
        }
        return $DiagnosticsConfigurations
    }

    $Label = $ENV:BUILD_BUILDNUMBER
    $StorageAccountKeysMap = @{}

    # Set Azure subscription object so there is a CurrentStorageAccountName property
    $Subscription = Get-AzureSubscription
    Set-AzureSubscription -CurrentStorageAccountName $ClassicStorageAccountName -SubscriptionId $Subscription.SubscriptionId

    Write-Host "##[command]Get-AzureService -ServiceName $ServiceName -ErrorAction SilentlyContinue -ErrorVariable azureServiceError"
    $AzureService = Get-AzureService -ServiceName $ServiceName -ErrorAction SilentlyContinue -ErrorVariable azureServiceError

    if ($AzureServiceError) {
        $AzureServiceError | ForEach-Object { Write-Verbose $_.Exception.ToString() }
    }

    if (!$AzureService) {
        Write-Host "##[command]New-AzureService -ServiceName $ServiceName -Location $ServiceLocation"
        $AzureService = New-AzureService -ServiceName $ServiceName -Location $ServiceLocation
    }

    $DiagnosticExtensions = Get-DiagnosticsExtension -StorageAccount $ClassicStorageAccountName -ExtensionsPath $ServiceConfigFile StorageAccountKeysMap $StorageAccountKeysMap

    Write-Host "##[command]Get-AzureDeployment -ServiceName $ServiceName -Slot $Slot -ErrorAction SilentlyContinue -ErrorVariable azureDeploymentError"
    $AzureDeployment = Get-AzureDeployment -ServiceName $ServiceName -Slot $Slot -ErrorAction SilentlyContinue -ErrorVariable azureDeploymentError

    if ($AzureDeploymentError) {
        $AzureDeploymentError | ForEach-Object { Write-Verbose $_.Exception.ToString() }
    }

    if (!$AzureDeployment) {
        Write-Host "##[command]New-AzureDeployment -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $Label -ExtensionConfiguration <extensions>"
        $AzureDeployment = New-AzureDeployment -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $Label -ExtensionConfiguration $DiagnosticExtensions

    }
    else {
        #Use -Upgrade
        Write-Host "##[command]Set-AzureDeployment -Upgrade -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $Label -ExtensionConfiguration <extensions>"
        $AzureDeployment = Set-AzureDeployment -Upgrade -ServiceName $ServiceName -Package $ServicePackageFile -Configuration $ServiceConfigFile -Slot $Slot -Label $Label -ExtensionConfiguration $DiagnosticExtensions
    }
}
catch {
    throw "$_"
}
