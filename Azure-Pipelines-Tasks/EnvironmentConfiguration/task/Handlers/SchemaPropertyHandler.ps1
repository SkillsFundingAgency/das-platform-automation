function Get-SchemaPropertyValue {
    [CmdletBinding(DefaultParameterSetName = "Standard")]
    Param(
        [Parameter(Mandatory = $true, ParameterSetName = "Standard")]
        [Parameter(Mandatory = $true, ParameterSetName = "AsInt")]
        [Parameter(Mandatory = $true, ParameterSetName = "AsBool")]
        $PropertyObject,
        [Parameter(Mandatory = $false, ParameterSetName = "AsInt")]
        [Switch]$AsInt,
        [Parameter(Mandatory = $false, ParameterSetName = "AsBool")]
        [Switch]$AsBool
    )

    try {

        Trace-VstsEnteringInvocation $MyInvocation

        if ($PropertyObject.ExtensionData.ContainsKey("environmentVariable")) {
            $TaskVariableParameters = @{
                Name   = $PropertyObject.ExtensionData.Item("environmentVariable").Value
                AsInt  = $AsInt.IsPresent
                AsBool = $AsBool.IsPresent
            }
            $TaskVariable = Get-VstsTaskVariable @TaskVariableParameters
        }

        if (!$TaskVariable -and	$PropertyObject.Default.Value) {
            $TaskVariable = $PropertyObject.Default.Value
        }

        if (!$TaskVariable) {
            throw "No environment variable found and no default value set in schema"
        }

        Write-Output $TaskVariable

    }
    catch {
        throw "Could not get property from object [ $($PropertyObject.ExtensionData.Item("environmentVariable").Value) ] : $_"
    }
    finally {
        Trace-VstsEnteringInvocation $MyInvocation
    }
}

function Expand-SchemaProperty {
    [CmdletBinding()][OutputType("System.Collections.Hashtable")]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        $PropertyObject
    )

    try {

        Trace-VstsEnteringInvocation $MyInvocation

        $ProcessedProperties = @{ }

        foreach ($Key in $PropertyObject.Keys) {

            $Property = $PropertyObject.Item($Key)
            Switch ($Property.Type.ToString()) {

                'Object' {
                    Write-Host "    - Object property: $($Key)"
                    $PropertyValue = Expand-SchemaProperty -PropertyObject $Property.Properties
                    break
                }

                'Array' {
                    Write-Host "        - Property: [Array]$($Key)"
                    $ArrayString = Get-SchemaPropertyValue -PropertyObject $Property
                    $DeserializedObject = [Newtonsoft.Json.JsonConvert]::DeserializeObject($ArrayString)
                    $PropertyValue = [System.Array]$DeserializedObject
                    break
                }

                'String' {
                    Write-Host "        - property: [String]$($Key)"
                    $PropertyValue = Get-SchemaPropertyValue -PropertyObject $Property
                    break
                }

                'Integer' {
                    Write-Host "        - property: [Integer]$($Key)"
                    $PropertyValue = Get-SchemaPropertyValue -PropertyObject $Property -AsInt
                    break
                }

                'Number' {
                    Write-Host "        - property: [Number]$($Key)"
                    $PropertyValue = [Decimal]::Parse((Get-SchemaPropertyValue -PropertyObject $Property))
                    break
                }

                'Boolean' {
                    Write-Host "        - property: [Bool]$($Key)"
                    $PropertyValue = Get-SchemaPropertyValue -PropertyObject $Property -AsBool
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
        throw $PScmdlet.ThrowTerminatingError($_)
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}
