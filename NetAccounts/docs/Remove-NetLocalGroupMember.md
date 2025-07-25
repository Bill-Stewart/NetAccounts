---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Remove-NetLocalGroupMember

## SYNOPSIS
Removes members from a local security group.

## SYNTAX

### Group (Default)
```
Remove-NetLocalGroupMember [-Group] <NetLocalGroupPrincipal> [-Member] <NetPrincipal[]> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Name
```
Remove-NetLocalGroupMember [-Name] <String> [-Member] <NetPrincipal[]> [-ComputerName <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### SID
```
Remove-NetLocalGroupMember [-SID] <SecurityIdentifier> [-Member] <NetPrincipal[]> [-ComputerName <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Removes members from a local security group.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Remove-NetLocalGroupMember -Group "Administrators" -Member "Admin02","CONTOSO\Domain Admins"
```
Removes members from the local Administrators security group on the current computer.

### EXAMPLE 2
```powershell
PS > Remove-NetLocalGroupMember -SID S-1-5-32-544 -Member (Get-WellknownPrincipal -DomainAdmins "FABRIKAM")
```
Removes the Domain Admins group from the FABRIKAM domain from the local Administrators security group on the current computer.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security group resides.
You cannot specify this parameter if you use the -Group parameter.
Omit this parameter to remove members from the local security group on the current computer.

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

### -Group
Specifies the local security group from which members will be removed.
Use Get-NetLocalGroup or Get-NetLocalAdminGroup to get a local security group for this parameter.

```yaml
Type: NetLocalGroupPrincipal
Parameter Sets: Group
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Member
Specifies one or members to remove from the local security group.
You can specify members by name, security identifier (SID), or NetPrincipal objects.

```yaml
Type: NetPrincipal[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies the name of the local security group from which members will be removed.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SID
Specifies the security identifier (SID) of the local security group from which members will be removed.

```yaml
Type: SecurityIdentifier
Parameter Sets: SID
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
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

### NetPrincipal
You can pipe NetPrincipal objects to specify local security group members.

## OUTPUTS

### None
Returns no output.

## NOTES

## RELATED LINKS
