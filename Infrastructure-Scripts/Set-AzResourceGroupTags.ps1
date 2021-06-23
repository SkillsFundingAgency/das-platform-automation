<#
    .SYNOPSIS
    Sets standard tags on a Resource Group required by the ESFA.

    .DESCRIPTION
    Checks if a Resource Group exists, if it doesn't, create with specified tags.  If it does exist, validates that the tags are match those specified in the parameters and updates them if necessary.

    .PARAMETER ResourceGroupName
    Name of the Resource Group to be created and/or have tags applied.

    .PARAMETER Location
    [Optional]Location of the Resource Group, defaults to West Europe.

    .PARAMETER Tags
    A hashtable of the tags to be assigned to the resource group

    .EXAMPLE
    Set-ResourceGroupTags -ResourceGroupName "das-at-foobar-rg" -Tags @{"Environment" = "Dev/Test";"Parent Business" = "Apprenticeships";"Service Offering" = "AS Commitments"}
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [string]$Location = "West Europe",
    [Parameter(Mandatory = $true)]
    [string]$Tags
)

try {

    $TagsHashTable = @{ }
    (ConvertFrom-Json $Tags).PSObject.Properties | ForEach-Object { $TagsHashTable[$_.Name] = $_.Value }

    Write-Verbose -Message "Attempting to retrieve existing resource group $ResourceGroupName"
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue

    if (!$ResourceGroup) {
        Write-Verbose -Message "Resource group $ResourceGroupName doesn't exist, creating resource group"
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $TagsHashTable
    }

    else {
        Write-Verbose -Message "Resource group $ResourceGroupName exists, validating tags"
        $UpdateTags = $false

        if ($ResourceGroup.Tags) {
            # --- Check existing tags and update if necessary
            $UpdatedTags = $ResourceGroup.Tags
            foreach ($Key in $TagsHashTable.Keys) {
                Write-Verbose "Current value of Resource Group Tag $Key is $($ResourceGroup.Tags[$Key])"

                if ($($ResourceGroup.Tags[$Key]) -eq $($TagsHashTable[$Key])) {
                    Write-Verbose -Message "Current value of tag ($($ResourceGroup.Tags[$Key])) matches parameter ($($TagsHashTable[$Key]))"
                }

                elseif ($null -eq $($ResourceGroup.Tags[$Key])) {
                    Write-Verbose -Message ("Tag value is not set, adding tag {0} with value {1}" -f $Key, $TagsHashTable[$Key])
                    $UpdatedTags[$Key] = $TagsHashTable[$Key]
                    $UpdateTags = $true
                }

                else {
                    Write-Verbose -Message ("Tag value is incorrect, setting tag {0} with value {1}" -f $Key, $TagsHashTable[$Key])
                    $UpdatedTags[$Key] = $TagsHashTable[$Key]
                    $UpdateTags = $true
                }

            }

        }

        else {
            # --- No tags to check, just update with the passed in tags
            $UpdatedTags = $TagsHashTable
            $UpdateTags = $true
        }

        if ($UpdateTags) {
            Write-Verbose -Message "Replacing existing tags:"
            $UpdatedTags
            Set-AzResourceGroup -Name $ResourceGroup.ResourceGroupName -Tag $UpdatedTags
        }

    }

}

catch {
    throw "$_"
}
