---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-NetLocalGroupMember

## SYNOPSIS
Gets members of local security groups.

## SYNTAX

### Group (Default)
```
Get-NetLocalGroupMember [-Group] <NetLocalGroupPrincipal[]> [<CommonParameters>]
```

### Name
```
Get-NetLocalGroupMember [-Name] <String[]> [-ComputerName <String>] [<CommonParameters>]
```

### SID
```
Get-NetLocalGroupMember [-SID] <SecurityIdentifier[]> [-ComputerName <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets members of local security groups.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Get-NetLocalGroupMember "Application Admins"
```

This command gets the members of a local security group on the current computer.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security groups reside.
Omit this parameter to get the members of local security groups on the current computer.

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
Specifies one or more local security groups.

```yaml
Type: NetLocalGroupPrincipal[]
Parameter Sets: Group
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies one or more names of local security groups.
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
Specifies one or more security security identifiers (SIDs) of local security groups.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### NetLocalGroupPrincipal
### You can pipe NetLocalGroupPrincipal objects to specify local security groups.
### String
You can pipe strings to specify the local security group names.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify the local security group SIDs.

## OUTPUTS

### NetPrincipal
Outputs NetPrincipal objects.

## NOTES
Get-NetLocalGroupMember does not get members of domain local security groups.

## RELATED LINKS
