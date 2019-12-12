<#
    .SYNOPSIS
    Sets Tags on All Resources in a Resource Group to match the Tags set on the Resource Group.

    .DESCRIPTION
    If The Resource Group exists and has been tagged reads the Tags assigned to the Resource Group and replicates them to all Resources within that Resource Group.
    If there is a Tag with a different Value it will be overwrittend,

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
        foreach ($Resource in $Resources) {
            $TagChanges = $false
            $ResourceTags = (Get-AzResource -ResourceId $Resource.ResourceId).Tags
            if ($ResourceTags) {
                foreach ($Key in $Group.Tags.Keys) {
                    if (-not($ResourceTags.ContainsKey($Key))) {
                        Write-Output "ADD: $($Resource.Name) - $Key"
                        $ResourceTags.Add($Key, $Group.Tags[$Key])
                        $TagChanges = $true
                    }
                    else {
                        if ($ResourceTags[$Key] -eq $Group.Tags[$Key]) {
                            # Key is up-to-date
                        }
                        else {
                            Write-Output "UPD: $($Resource.Name) - $Key"
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
                Write-Output "ADD: $($Resource.Name) - All tags from RG"
                $TagsToWrite = $Group.Tags
                $TagChanges = $true
            }
            if ($TagChanges) {
                try {
                    $Result = Set-AzResource -Tag $TagsToWrite -ResourceId $Resource.ResourceId -Force -ErrorAction Stop
                    Write-Output $Result
                }
                catch {
                    Write-Error "$($Resource.Name) - $($Group.ResourceID) : $_.Exception"
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
