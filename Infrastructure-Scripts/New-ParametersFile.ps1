<#
    .SYNOPSIS
    Dynamically create a parameters.json file from an arm template

    .DESCRIPTION
    Dynamically create a parameters.json file with values from an arm template and environment variables matching the arm template parameters

    .PARAMETER TemplateFilePath
    File path to the ARM template

    .PARAMETER ParametersFilePath
    File path to store the generated Parameters

    .EXAMPLE
    New-ParametersFile.ps1 -TemplateFilePath "C:\template.json" -ParametersFilePath "C:\template.parameters.json"
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$TemplateFilePath,
    [Parameter(Mandatory = $true)]
    [String]$ParametersFilePath
)

try {
    $TemplateParameters = (Get-Content -Path $TemplateFilePath -Raw | ConvertFrom-Json).Parameters
}
catch {
    Write-Error "Failed to convert $TemplateFilePath to JSON"
    throw $_
}

$ParametersFile = [PSCustomObject]@{
    "`$schema"     = "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#"
    contentVersion = "1.0.0.0"
    parameters     = @{ }
}
$ParameterObjects = $TemplateParameters.PSObject.Members | Where-Object MemberType -eq NoteProperty

foreach ($ParameterObject in $ParameterObjects) {
    $ParameterType = $ParameterObject.Value.Type
    $ParameterName = $ParameterObject.Name
    $ParameterValue = (Get-Item -Path "env:$ParameterName" -ErrorAction SilentlyContinue).Value

    if (!$ParameterValue) {
        Write-Host -Message "Environment variable for $ParameterName was not found, attempting UpperCase"
        $ParameterName = $ParameterObject.Name.ToUpper()
        $ParameterValue = (Get-Item -Path "env:$ParameterName" -ErrorAction SilentlyContinue).Value
        if (!$ParameterValue){
            Write-Host -Message "Environment variable for $ParameterName was not found, attempting default value"
            if ($null -eq $ParameterObject.Value.defaultValue) {
                Write-Verbose -Message "Default value for $ParameterName was not found. Process will terminate"
                throw "Could not find environment variable or default value for template parameter $ParameterName"
            }
            else {
                Write-Verbose -Message "Parameter $ParameterName has a default value, skipping this parameter"
                continue
            }
        }

        if ($ParameterType -eq "object") {
            $ParameterValue = $ParameterValue | ConvertTo-Json -Depth 10
        }
    }
    else {
        Write-Verbose -Message "Using environment variable value for $ParameterName"
    }

    Write-Verbose "Processing parameter $ParameterName as type $ParameterType"
    switch ($ParameterType) {
        'array' {
            # If Default value is an empty array
            if (!$ParameterValue -or $ParameterValue -eq "[]") {
                $ParameterValue = @()
            }
            elseif (($ParameterValue | ConvertFrom-Json | Get-Member)[0].TypeName -eq "System.String") {
                $ParameterValue = [String[]]($ParameterValue | ConvertFrom-Json)
            }
            else {
                $HashTable = @{ }
                (ConvertFrom-Json $ParameterValue).psobject.properties | ForEach-Object { $HashTable[$_.Name] = $_.Value }
                $ParameterValue = @($HashTable.SyncRoot)
            }

            break
        }
        'bool' {
            # In the case of default values do a type comparison
            if ($ParameterValue -is [Boolean]) {
                break
            }
            if ($ParameterValue.ToLower() -eq "true") {
                $ParameterValue = $true
                break
            }
            if ($ParameterValue.ToLower() -eq "false") {
                $ParameterValue = $false
                break
            }
            throw "Not a valid boolean input for $ParameterName"
        }
        'int' {
            $ParameterValue = [Int]$ParameterValue
            break
        }
        'object' {
            # Write-Verbose -Message "$ParameterName type: $(($ParameterValue | ConvertFrom-Json | Get-Member)[0].TypeName)"
            # if(($ParameterValue | ConvertFrom-Json | Get-Member)[0].TypeName -eq "System.String"){
            #     Write-Verbose -Message "$ParameterName is object but value is a string"
            #     if ($ParameterValue)
            # }
            $ParameterValue = ([Regex]::Unescape(($ParameterValue)) | ConvertFrom-Json -Depth 10)
            break
        }
    }

    $ParametersFile.parameters.Add($ParameterName, @{ value = $ParameterValue })
}

$null = Set-Content -Path $ParametersFilePath -Value ([Regex]::Unescape(($ParametersFile | ConvertTo-Json -Depth 10))) -Force
Write-Output "Parameter file content saved to $ParametersFilePath"

Start-Sleep -Seconds 180
