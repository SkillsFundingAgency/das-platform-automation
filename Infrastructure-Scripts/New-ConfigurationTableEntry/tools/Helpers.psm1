function Build-ConfigurationEntity {
    <#
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$SchemaDefinitionPath
    )

    try {
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
    catch {
        Write-Error -Message "$_" -ErrorAction Stop
    }
    finally {
    }
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

    try {
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
    catch {
        Write-Error -Message "$_" -ErrorAction Stop
    }
    finally {
    }
}

function Test-ConfigurationEntity {
    <#
#>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [String]$Configuration,
        [Parameter(Mandatory = $true)]
        [String]$SchemaDefinitionPath
    )

    try {
        Write-Host "Validating $($Script:EmojiDictionary.StopWatch)"
        $SchemaDefinition = Get-Content -Path $SchemaDefinitionPath -Raw
        $SchemaObject = [Newtonsoft.Json.Schema.JSchema, Newtonsoft.Json.Schema, Version = 2.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Parse($SchemaDefinition)

        $ConfigurationObject = [Newtonsoft.Json.Linq.JObject, Newtonsoft.Json, Version = 9.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Parse($Configuration)
        [Newtonsoft.Json.Schema.SchemaExtensions, Newtonsoft.Json.Schema, Version = 2.0.0.0, Culture = neutral, PublicKeyToken = 30ad4fe6b2a6aeed]::Validate($ConfigurationObject, $SchemaObject)

        Write-Host "Configuration validated $($Script:EmojiDictionary.GreenCheck)"
    }
    catch {
        Write-Error -Message "Validation failed: $_`n$($_.Exception.InnerException.Message)" -ErrorAction Stop
    }
    finally {
    }
}

function Expand-Schema {
    [CmdletBinding()][OutputType("System.Collections.Hashtable")]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        $PropertyObject
    )

    try {
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
    catch {
        Write-Error -Message "Failed to expand schema property [$Key] $_" -ErrorAction Stop
    }
    finally {
    }
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

    try {
        if ($PropertyObject.ExtensionData.ContainsKey("environmentVariable")) {

            $VariableName = $PropertyObject.ExtensionData.Item("environmentVariable").Value
            ##TO DO: reconsider how values are aquired from pipeline variables
            $TaskVariable = Get-VstsTaskVariable -Name $VariableName
            if (![string]::IsNullOrEmpty($TaskVariable)) {
                switch ($PSCmdlet.ParameterSetName) {

                    'Standard' {
                        $TaskVariable = "$($TaskVariable)"
                        break
                    }

                    'AsInt' {
                        $TaskVariable = [int]$TaskVariable
                        break
                    }

                    'AsNumber' {
                        $TaskVariable = [Decimal]::Parse($TaskVariable)
                        break
                    }

                    'AsArray' {
                        $TaskVariable = @($TaskVariable | ConvertFrom-Json)
                        break
                    }

                    'AsBool' {
                        $TaskVariable = $TaskVariable.ToLower() -in '1', 'true'
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
    catch {
        Write-Error -Message "Could not get property from object [ $VariableName ] : $_" -ErrorAction Stop
    }
    finally {
    }
}

function Get-StorageAccountKey {
    <#
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Name
    )

    try {
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
    catch {
        Write-Error -Message "Failed to retrieve key from $($Name): $_" -ErrorAction Stop
    }
    finally {
    }
}

function Get-TableEntity {
    <#
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [PSObject]$StorageTable,
        [Parameter(Mandatory = $true)]
        [String]$PartitionKey,
        [Parameter(Mandatory = $true)]
        [String]$RowKey
    )

    try {
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
    catch {
        Write-Error -Message "$_" -ErrorAction Stop
    }
    finally {
    }
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

    try {
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
    catch {
        Write-Error -Message "$_" -ErrorAction Stop
    }
    finally {
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

    try {
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
    catch {
        Write-Error -Message "$_" -ErrorAction Stop
    }
    finally {
    }
}
