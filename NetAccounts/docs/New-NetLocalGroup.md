---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# New-NetLocalGroup

## SYNOPSIS
Creates a local security group.

## SYNTAX

```
New-NetLocalGroup [-Name] <String> [-Description <String>] [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Creates a local security group.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > New-NetLocalGroup "Application Admins" -Description "Members of this group can administer applications."
```
Creates a new local security group on the current computer with the specified name and description.

## PARAMETERS

### -ComputerName
Specifies the computer name where to create the local security group.
Omit this parameter to create the local security group on the current computer.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
Specifies a description for the local security group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
Specifies a name for the local security group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

### String
You can a string to specify a local security group name.

## OUTPUTS

### NetLocalGroupPrincipal
Outputs a NetLocalGroupPrincipal object for the group.

## NOTES

## RELATED LINKS
