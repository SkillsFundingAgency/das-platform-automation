# --- Install packages & load libraries
Write-Host "Registering package sources"
Register-PackageSource -Name NuGet -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Trusted -ErrorAction SilentlyContinue
$PackageConfig = [Xml](Get-Content -Path $PSScriptRoot\..\tools\packages.config -Raw)
foreach ($Package in $PackageConfig.packages.package) {
    Write-Host "Installing package $($Package.Id)"
    $PackageParameters = @{
        Destination      = "$PSScriptRoot/packages"
        Name             = $Package.id
        RequiredVersion  = $Package.version
        SkipDependencies = $True
        ProviderName     = "Nuget"
        Source           = "Nuget"
    }

    $null = Install-Package @PackageParameters -Verbose:$VerbosePreference -ForceBootstrap
    Add-Type -Path "$PSScriptRoot/packages/$($Package.id).$($Package.version)/lib/$($Package.targetFramework)/$($Package.id).dll"
}


$Script:EmojiDictionary = @{
    GreenCheck = [System.Text.Encoding]::UTF32.GetString(@(20, 39, 0, 0))
    StopWatch  = [System.Text.Encoding]::UTF32.GetString(@(241, 35, 0, 0))
    Lightning  = [System.Text.Encoding]::UTF32.GetString(@(161, 38, 0, 0))
}

function Build-ConfigurationEntity {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$SchemaDefinitionPath
    )

    Write-Host "Parsing schema: $(([System.IO.FileInfo]$SchemaDefinitionPath).Name) $($Script:EmojiDictionary.Lightning)"
    $SchemaDefinition = Get-Content -Path $SchemaDefinitionPath -Raw
    $SchemaObject = [Newtonsoft.Json.Schema.JSchema, Newtonsoft.Json.Schema, Version = 2.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Parse($SchemaDefinition)

    Write-Host "Processing properties"
    $Settings = [Newtonsoft.Json.JsonSerializerSettings, Newtonsoft.Json, Version = 9.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::new()
    $Settings.MaxDepth = 100
    $Schema = Expand-Schema -PropertyObject $SchemaObject.Properties
    $Configuration = ($Schema | ConvertTo-Json -Depth 10 -Compress)

    if ($PSVersionTable.PSVersion.Major -lt 6) {
        $Configuration = [Regex]::Replace($Configuration,
            "\\u(?<Value>[a-zA-Z0-9]{4})", {
                param($m) ([char]([int]::Parse($m.Groups['Value'].Value,
                            [System.Globalization.NumberStyles]::HexNumber))).ToString() } )
    }

    Write-Output $Configuration
}

function New-ConfigurationEntity {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$StorageAccount,
        [Parameter(Mandatory = $true)]
        [String]$TableName,
        [Parameter(Mandatory = $true)]
        [String]$PartitionKey,
        [Parameter(Mandatory = $true)]
        [String]$RowKey,
        [Parameter(Mandatory = $true)]
        [String]$Configuration
    )

    Write-Verbose -Message "Building storage context"
    $StorageAccountKey = Get-StorageAccountKey -Name $StorageAccount
    $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageAccountKey

    Write-Verbose -Message "Searching for storage table $TableName"
    $StorageTable = Get-AzureStorageTable -Context $StorageContext -Name $TableName -ErrorAction SilentlyContinue
    if (!$StorageTable) {
        Write-Verbose -Message "Creating a new storage table $TableName"
        $StorageTable = New-AzureStorageTable -Context $StorageContext -Name $TableName
    }

    $Entity = Get-TableEntity -StorageTable $StorageTable -PartitionKey $PartitionKey -RowKey $RowKey

    if ($Entity) {
        Write-Host "Updating existing entity [$RowKey]"
        Set-TableEntity -Configuration $Configuration -Entity $Entity
    }
    else {
        Write-Host "Creating a new entity [$RowKey]"
        New-TableEntity -Configuration $Configuration -PartitionKey $PartitionKey -RowKey $RowKey
    }
}

function Test-ConfigurationEntity {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$Configuration,
        [Parameter(Mandatory = $true)]
        [String]$SchemaDefinitionPath
    )
    ##TO DO: improve this, reports 1 failed property at a time, should report all failures

    Write-Host "Validating $($Script:EmojiDictionary.StopWatch)"
    $SchemaDefinition = Get-Content -Path $SchemaDefinitionPath -Raw
    $SchemaObject = [Newtonsoft.Json.Schema.JSchema, Newtonsoft.Json.Schema, Version = 2.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Parse($SchemaDefinition)

    $ConfigurationObject = [Newtonsoft.Json.Linq.JObject, Newtonsoft.Json, Version = 9.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Parse($Configuration)
    [Newtonsoft.Json.Schema.SchemaExtensions, Newtonsoft.Json.Schema, Version = 2.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Validate($ConfigurationObject, $SchemaObject)

    ##TO DO: fix this, writes success message on failure
    Write-Host "Configuration validated $($Script:EmojiDictionary.GreenCheck)"
}

function Expand-Schema {
    [CmdletBinding()][OutputType("System.Collections.Hashtable")]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        $PropertyObject
    )

    [Hashtable]$ProcessedProperties = @{ }
    foreach ($Key in $PropertyObject.Keys) {

        $Property = $PropertyObject.Item($Key)
        Switch ($Property.Type.ToString()) {

            'Object' {
                Write-Host "    -> [Object]$($Key)"
                $PropertyValue = Expand-Schema -PropertyObject $Property.Properties
                break
            }

            'Array' {
                Write-Host "    -> [Array]$($Key)"
                $PropertyValue = Get-SchemaProperty -PropertyObject $Property -AsArray
                break
            }

            'String' {
                Write-Host "    -> [String]$($Key)"
                $PropertyValue = Get-SchemaProperty -PropertyObject $Property
                break
            }

            'Integer' {
                Write-Host "    -> [Integer]$($Key)"
                $PropertyValue = Get-SchemaProperty -PropertyObject $Property -AsInt
                break
            }

            'Number' {
                Write-Host "    -> [Number]$($Key)"
                $PropertyValue = Get-SchemaProperty -PropertyObject $Property -AsNumber
                break
            }

            'Boolean' {
                Write-Host "    -> [Bool]$($Key)"
                $PropertyValue = Get-SchemaProperty -PropertyObject $Property -AsBool
                break
            }

            Default {
                $PropertyValue = "Undefined"
                break
            }

        }

        $ProcessedProperties.Add($Key, $PropertyValue)
    }

    Write-Output $ProcessedProperties
}

function Get-SchemaProperty {
    [CmdletBinding(DefaultParameterSetName = "Standard")]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $true, ParameterSetName = "AsInt")]
        [Parameter(Mandatory = $true, ParameterSetName = "AsNumber")]
        [Parameter(Mandatory = $true, ParameterSetName = "AsArray")]
        [Parameter(Mandatory = $true, ParameterSetName = "AsBool")]
        $PropertyObject,
        [Parameter(Mandatory = $false, ParameterSetName = "AsInt")]
        [Switch]$AsInt,
        [Parameter(Mandatory = $false, ParameterSetName = "AsNumber")]
        [Switch]$AsNumber,
        [Parameter(Mandatory = $false, ParameterSetName = "AsArray")]
        [Switch]$AsArray,
        [Parameter(Mandatory = $false, ParameterSetName = "AsBool")]
        [Switch]$AsBool
    )

    if ($PropertyObject.ExtensionData.ContainsKey("environmentVariable")) {

        $VariableName = $PropertyObject.ExtensionData.Item("environmentVariable").Value
        $TaskVariable = Get-Variable -Name $VariableName
        if (![string]::IsNullOrEmpty($TaskVariable)) {
            switch ($PSCmdlet.ParameterSetName) {

                'Standard' {
                    $TaskVariable = "$($TaskVariable.Value)"
                    break
                }

                'AsInt' {
                    $TaskVariable = [int]$TaskVariable.Value
                    break
                }

                'AsNumber' {
                    $TaskVariable = [Decimal]::Parse($TaskVariable.Value)
                    break
                }

                'AsArray' {
                    $TaskVariable = @($TaskVariable.Value | ConvertFrom-Json)
                    break
                }

                'AsBool' {
                    $TaskVariable = $TaskVariable.Value.ToLower() -in '1', 'true'
                    break
                }
            }
            return $TaskVariable
        }
    }

    if ($null -ne $PropertyObject.Default) {
        Write-Verbose -Message "No environment variable found but a default value is present in the schema"
        $TaskVariable = $PropertyObject.Default.Value
        Write-Verbose -Message "Set default value '$TaskVariable'"
        return $TaskVariable
    }

    throw "No environment variable found and no default value set in schema"
}

function Get-StorageAccountKey {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name
    )

    if ($Global:IsAz) {
        $StorageAccount = Get-AzureRmResource -Name $Name -ResourceType "Microsoft.Storage/storageAccounts" -ErrorAction Stop
    }
    elseif ($Global:IsAzureRm) {
        $StorageAccount = Find-AzureRmResource -Name $Name -ResourceType "Microsoft.Storage/storageAccounts" -ErrorAction Stop
    }

    if (!$StorageAccount) {
        Write-Error -Message "Could not find storage account resource." -ErrorAction Stop
    }

    $StorageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $StorageAccount.ResourceGroupName -Name $Name)[0].Value
    Write-Output $StorageAccountKey
}

function Get-TableEntity {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$StorageTable,
        [Parameter(Mandatory = $true)]
        [String]$PartitionKey,
        [Parameter(Mandatory = $true)]
        [String]$RowKey
    )

    if ($Global:IsAz) {
        $TableOperation = [Microsoft.Azure.Cosmos.Table.TableOperation]::Retrieve($PartitionKey, $RowKey)
    }
    elseif ($Global:IsAzureRm) {
        $TableOperation = [Microsoft.WindowsAzure.Storage.Table.TableOperation]::Retrieve($PartitionKey, $RowKey)
    }
    else {
        throw "Couldn't find Global Azure module setting $($MyInvocation.ScriptLineNumber) $($MyInvocation.ScriptName)"
    }
    $Entity = $StorageTable.CloudTable.Execute($TableOperation, $null, $null)

    Write-Output $Entity.Result
}

function New-TableEntity {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Configuration,
        [Parameter(Mandatory = $true)]
        [String]$PartitionKey,
        [Parameter(Mandatory = $true)]
        [String]$RowKey
    )

    if ($Global:IsAz) {
        $Entity = [Microsoft.Azure.Cosmos.Table.DynamicTableEntity]::new($PartitionKey, $RowKey)
        $Entity.Properties.Add("Data", $Configuration)
        $null = $StorageTable.CloudTable.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::Insert($Entity))
    }
    elseif ($Global:IsAzureRm) {
        $Entity = [Microsoft.WindowsAzure.Storage.Table.DynamicTableEntity]::new($PartitionKey, $RowKey)
        $Entity.Properties.Add("Data", $Configuration)
        $null = $StorageTable.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::Insert($Entity))
    }
    else {
        throw "Couldn't find Global Azure module setting $($MyInvocation.ScriptLineNumber) $($MyInvocation.ScriptName)"
    }
}

function Set-TableEntity {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Configuration,
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity
    )

    $Entity.Properties["Data"].StringValue = $Configuration
    if ($Global:IsAz) {
        $null = $StorageTable.CloudTable.Execute([Microsoft.Azure.Cosmos.Table.TableOperation]::InsertOrReplace($Entity))
    }
    elseif ($Global:IsAzureRm) {
        $null = $StorageTable.CloudTable.Execute([Microsoft.WindowsAzure.Storage.Table.TableOperation]::InsertOrReplace($Entity))
    }
    else {
        throw "Couldn't find Global Azure module setting $($MyInvocation.ScriptLineNumber) $($MyInvocation.ScriptName)"
    }
}
