---
external help file:
Module Name:
online version:
schema: 2.0.0
---

# Get-AzStorageAccountConnectionString

## SYNOPSIS
Return either the primary or secondary connection string for a Storage Account and write to a Azure Pipelines variable.

## SYNTAX

```
Get-AzStorageAccountConnectionString [-ResourceGroup] <String> [-StorageAccount] <String> [-UseSecondaryKey]
 [-OutputVariable] <String> [<CommonParameters>]
```

## DESCRIPTION
Return either the primary or secondary connection string for a Storage Account and write to a Azure Pipelines variable.

## EXAMPLES

### EXAMPLE 1
```
.\Get-StorageAccountConnectionString.ps1 -ResourceGroup rgname -StorageAccount saname
```

Returns the Primary Storage Account connection string.

### EXAMPLE 2
```
.\Get-StorageAccountConnectionString.ps1 -ResourceGroup rgname -StorageAccount saname -UseSecondaryKey
```

Returns the Secondary Storage Account connection string.

### EXAMPLE 3
```
.\Get-StorageAccountConnectionString.ps1 -ResourceGroup rgname -StorageAccount saname -OutputVariable "CustomOutputVariable"
```

Returns the Primary Storage Account connection string and specifies a custom output variable to be used in VSTS.

## PARAMETERS

### -ResourceGroup
The name of the Resource Group that contains the Storage Account.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -StorageAccount
The name of the Storage Account.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseSecondaryKey
Boolean Switch to return the secondary connection string.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputVariable
The name of the variable to be used by Azure Pipelines.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: StorageConnectionString
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
