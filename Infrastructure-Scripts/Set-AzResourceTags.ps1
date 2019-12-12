<#
    .SYNOPSIS
    Sets standard tags on Resources in a Resource Group to match those on the Resource Group.

    .DESCRIPTION
    Checks if a Resource Group exists,  If it does exist, creates or updates the Standard Tags on any Resource in the Resource Group to match those of the
    parent Resource group without removing any additions

    .PARAMETER ResourceGroupName
    Name of the Resource Group to be created and/or have tags applied.


    .EXAMPLE
    Set-ResourceTags -ResourceGroupName "das-at-foobar-rg"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName
)

try {
    $Group = Get-AzResourceGroup -ResourceGroupName $ResourceGroupName
    if ($null -ne $Group.Tags) {
        $Resources = Get-AzResource -ResourceGroupName $Group.ResourceGroupName
        foreach ($R in $Resources) {
            $TagChanges = $false
            $ResourceTags = (Get-AzResource -ResourceId $R.ResourceId).Tags
            if ($ResourceTags) {
                foreach ($Key in $Group.Tags.Keys) {
                    if (-not($ResourceTags.ContainsKey($Key))) {
                        Write-Output "ADD: $($R.Name) - $Key"
                        $ResourceTags.Add($Key, $Group.Tags[$Key])
                        $TagChanges = $true
                    }
                    else {
                        if ($ResourceTags[$Key] -eq $Group.Tags[$Key]) {
                            # Key is up-to-date
                        }
                        else {
                            Write-Output "UPD: $($R.Name) - $Key"
                            $null = $ResourceTags.Remove($Key)
                            $ResourceTags.Add($Key, $Group.Tags[$Key])
                            $TagChanges = $true
                        }
                    }
                }
                $TagsToWrite = $ResourceTags
            }
            else {
                # All tags missing
                Write-Output "ADD: $($R.Name) - All tags from RG"
                $TagsToWrite = $Group.Tags
                $TagChanges = $true
            }
            if ($TagChanges) {
                try {
                    $Result = Set-AzResource -Tag $TagsToWrite -ResourceId $R.ResourceId -Force -ErrorAction Stop
                    Write-Output $Result
                }
                catch {
                    # Write-Error "$($R.Name) - $($Group.ResourceID) : $_.Exception"
                }
            }
        }
    }
    else {
        Write-Warning "$ResourceGroupName has no tags set."
    }
}

catch {
    throw "$_"
}
