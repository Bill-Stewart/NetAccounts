---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Add-NetLocalGroupMember

## SYNOPSIS
Adds members to a local security group.

## SYNTAX

### Group (Default)
```
Add-NetLocalGroupMember [-Group] <NetLocalGroupPrincipal> [-Member] <NetPrincipal[]> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Name
```
Add-NetLocalGroupMember [-Name] <String> [-Member] <NetPrincipal[]> [-ComputerName <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### SID
```
Add-NetLocalGroupMember [-SID] <SecurityIdentifier> [-Member] <NetPrincipal[]> [-ComputerName <String>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Adds members to a local security group.
Local security groups are specific to individual computers.
If the computer is not joined to a domain, you can add local user accounts to a local security group.
If the computer is joined to a domain, you can add local user accounts, domain user accounts, computer accounts, and domain security groups from that domain and from trusted domains to a local security group.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Add-NetLocalGroupMember -Group "Administrators" -Member "Admin02","CONTOSO\Domain Admins"
```

Adds members to the local Administrators security group on the current computer.

### EXAMPLE 2
```powershell
PS > Add-NetLocalGroupMember -SID S-1-5-32-544 -Member (Get-WellknownPrincipal -DomainAdmins "FABRIKAM")
```

Adds the Domain Admins group from the FABRIKAM domain to the local Administrators security group on the current computer.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security group resides.
You cannot specify this parameter if you use the -Group parameter.
Omit this parameter to add members to the local security group on the current computer.

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
Specifies the local security group to which members will be added.
Use Get-NetLocalGroup or Get-NetLocalAdminGroup to get a local security group for this parameter.

```yaml
Type: NetLocalGroupPrincipal
Parameter Sets: Group
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Member
Specifies one or members to add to the local security group.
You can specify members by name, security identifier (SID), or NetPrincipal objects.
You cannot add a local security group as a member of another local security group.


```yaml
Type: NetPrincipal[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies the name of the local security group to which members will be added.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SID
Specifies the security identifier (SID) of the local security group to which members will be added.

```yaml
Type: SecurityIdentifier
Parameter Sets: SID
Aliases:

Required: True
Position: 0
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
Add-NetLocalGroupMember does not add members to domain local security groups.

You cannot add a local security group as a member of another local security group.

## RELATED LINKS
