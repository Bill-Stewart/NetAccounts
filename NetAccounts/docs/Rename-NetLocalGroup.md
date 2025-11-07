---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Rename-NetLocalGroup

## SYNOPSIS
Renames a local security group.

## SYNTAX

### InputObject (Default)
```
Rename-NetLocalGroup [-InputObject] <NetLocalGroupPrincipal> [-NewName] <String> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Name
```
Rename-NetLocalGroup [-Name] <String> [-NewName] <String> [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### SID
```
Rename-NetLocalGroup [-SID] <SecurityIdentifier> [-NewName] <String> [-ComputerName <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Renames a local security group.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Rename-NetLocalGroup "APP_ADMIN" "Application Admins"
```

Renames a local security group on the current computer.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security group resides.
Omit this parameter to rename the local security group on the current computer.

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
Specifies the local security group to rename.

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
Specifies the name of the local security group to rename.
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

### -NewName
Specifies the new name for the local security group.

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

### -SID
Specifies the security identifier (SID) of the local security group to rename.

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
You can pipe a NetLocalGroupPrincipal object to specify the local security group.

### String
You can pipe a string to specify the name of the local security group.

### Security.Principal.SecurityIdentifier
You can pipe a SecurityIdentifier object to specify the security ID of the local security group.

## OUTPUTS

### None
Returns no output.

## NOTES
Rename-NetLocalGroup does not rename domain local security groups.

## RELATED LINKS
