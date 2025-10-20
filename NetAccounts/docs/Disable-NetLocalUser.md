---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Disable-NetLocalUser

## SYNOPSIS
Disables local user accounts.

## SYNTAX

### InputObject (Default)
```
Disable-NetLocalUser [-InputObject] <NetLocalUserPrincipal[]> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Name
```
Disable-NetLocalUser [-Name] <String[]> [-ComputerName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### SID
```
Disable-NetLocalUser [-SID] <SecurityIdentifier[]> [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Disables local user accounts.
Local user accounts are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Disable-NetLocalUser -Name "Admin02"
```

Disables a local user account by specifying its name.

### EXAMPLE 2
```powershell
PS > Get-NetLocalUser Guest | Disable-NetLocalUser
```

This command gets the local Guest user account by using Get-NetLocalUser, and then passes it to the Disable-NetLocalUser cmdlet by using the pipeline operator (|), which disables the local user account.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local user account(s) reside.
Omit this parameter to disable local user accounts on the current computer.

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
Specifies one or more local user account(s) to disable.

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
Specifies one or more names of local user account(s) to disable.
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
Specifies one or more security idetifiers (SIDs) of local user account(s) to disable.

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
You can pipe NetLocalUserPrincipal objects to specify the local user accounts.

### String
You can pipe strings to specify the names of local user accounts.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify the security IDs of local user accounts.

## OUTPUTS

### None
Returns no output.

## NOTES

## RELATED LINKS
