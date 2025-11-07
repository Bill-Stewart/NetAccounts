---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Remove-NetLocalUser

## SYNOPSIS
Removes local user accounts.

## SYNTAX

### InputObject (Default)
```
Remove-NetLocalUser [-InputObject] <NetLocalUserPrincipal[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name
```
Remove-NetLocalUser [-Name] <String[]> [-ComputerName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### SID
```
Remove-NetLocalUser [-SID] <SecurityIdentifier[]> [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Removes local user accounts.
Local user accounts are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Remove-NetLocalUser AppAdmin
```

Removes a local user account from the current computer. The command will prompt for confirmation.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local user accounts reside.
Omit this parameter to remove local user accounts on the current computer.

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
Specifies or or more local user accounts to remove.

```yaml
Type: NetLocalUserPrincipal[]
Parameter Sets: InputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies one or more names of local user accounts to remove.
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
Specifies one or more security identifiers of local user accounts to remove.

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

### NetLocalUserPrincipal
You can pipe NetLocalUserPrincipal objects to specify local user accounts.

### String
You can pipe strings to specify local user account names.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify security IDs for local user accounts.

## OUTPUTS

### None
Returns no output.

## NOTES
Remove-NetLocalUser does not remove domain user accounts.

Remove-NetLocalUser prompts for confirmation by default. To bypass the confirmation prompt, specify '-Confirm:$false'.

## RELATED LINKS
