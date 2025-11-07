---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Set-NetLocalGroup

## SYNOPSIS
Changes local security groups.

## SYNTAX

### InputObject (Default)
```
Set-NetLocalGroup [-InputObject] <NetLocalGroupPrincipal> -Description <String> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Name
```
Set-NetLocalGroup [-Name] <String> -Description <String> [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### SID
```
Set-NetLocalGroup [-SID] <SecurityIdentifier> -Description <String> [-ComputerName <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Changes local security groups.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Set-NetLocalGroup "Application Admins" -Description "Members of this group can administer applications."
```

Sets the description for a local security group on the current computer.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security group resides.
Omit this parameter to change the local security group on the current computer.

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

### -Description
Specifies a description for the local security group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
Specifies the local security group to change.

```yaml
Type: NetLocalGroupPrincipal
Parameter Sets: InputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies the name of the local security group to change.
Wildcards are not permitted.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SID
Specifies the security identifier (SID) of the local security group to change.

```yaml
Type: SecurityIdentifier
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
You can pipe SecurityIdentifier objects to specify security IDs of local security groups.

## OUTPUTS

### None
Returns no output.

## NOTES
Set-NetLocalGroup does not change domain local security groups.

## RELATED LINKS
