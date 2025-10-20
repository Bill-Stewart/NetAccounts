---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Remove-NetLocalGroup

## SYNOPSIS
Removes local security groups.

## SYNTAX

### InputObject (Default)
```
Remove-NetLocalGroup [-InputObject] <NetLocalGroupPrincipal[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name
```
Remove-NetLocalGroup [-Name] <String[]> [-ComputerName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### SID
```
Remove-NetLocalGroup [-SID] <SecurityIdentifier[]> [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Removes local security groups.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Remove-NetLocalGroup "Security Group 04"
```

Removes a local security group from the current computer. The command will prompt for confirmation.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security groups reside.
Omit this parameter to remove local security groups on the current computer.

```yaml
Type: String
Parameter Sets: Name, SID
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Specifies one or more local security groups to remove.

```yaml
Type: NetLocalGroupPrincipal[]
Parameter Sets: InputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies one or more names of local security groups to remove.
Wildcards are not permitted.

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SID
Specifies one or more security identifiers (SIDs) of local security groups to remove.

```yaml
Type: SecurityIdentifier[]
Parameter Sets: SID
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Confirm
Prompts for confirmation before taking an action.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what action would be taken without taking the action.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### NetLocalGroupPrincipal
You can pipe NetLocalGroupPrincipal objects to specify local security groups.

### String
You can pipe strings to specify local security group names.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify security IDs for local security groups.

## OUTPUTS

### None
Returns no output.

## NOTES
Remove-NetLocalGroup prompts for confirmation by default. To bypass the confirmation prompt, specify '-Confirm:$false'.

## RELATED LINKS
