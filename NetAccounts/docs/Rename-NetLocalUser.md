---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Rename-NetLocalUser

## SYNOPSIS
Renames a local user account.

## SYNTAX

### InputObject (Default)
```
Rename-NetLocalUser [-InputObject] <NetLocalUserPrincipal> [-NewName] <String> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Name
```
Rename-NetLocalUser [-Name] <String> [-NewName] <String> [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### SID
```
Rename-NetLocalUser [-SID] <SecurityIdentifier> [-NewName] <String> [-ComputerName <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Renames a local user account.
Local user accounts are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Rename-NetLocalUser Admin AppAdmin
```
Renames a local user account on the current computer.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local user account resides.
Omit this parameter to rename the local user account on the current computer.

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
Specifies the local account to rename.

```yaml
Type: NetLocalUserPrincipal
Parameter Sets: InputObject
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies the name of the local user account to rename.
Wildcards are not permitted.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -NewName
Specifies the new name for the local user account.

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

### -SID
Specifies the security identifier (SID) of the local user account to rename.

```yaml
Type: SecurityIdentifier
Parameter Sets: SID
Aliases:

Required: True
Position: 1
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

### NetLocalUserPrincipal
You can pipe a NetLocalUserPrincipal object to specify the local user account.

### String
You can pipe a string to specify the name of the local user account.

### Security.Principal.SecurityIdentifier
You can pipe a SecurityIdentifier object to specify the security ID of the local user account.

## OUTPUTS

### None
Returns no output.

## NOTES

## RELATED LINKS
