---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-NetLocalGroup

## SYNOPSIS
Gets local security groups.

## SYNTAX

### Name (Default)
```
Get-NetLocalGroup [[-Name] <String[]>] [-ComputerName <String>] [<CommonParameters>]
```

### SID
```
Get-NetLocalGroup [-SID] <SecurityIdentifier[]> [-ComputerName <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets local security groups.
Local security groups are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Get-NetLocalGroup "Application Admins"
```

Gets a local security group on the current computer. The command outputs properties of the local security group.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local security groups reside.
Omit this parameter to get local security groups on the current computer.

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
Specifies one or more names of local security groups.
Wildcards are not permitted.
Omit this parameter to get all local security groups.

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SID
Specifies one or more security identifiers (SIDs) of local security groups.

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

### String
You can pipe strings to specify local security group names.

### SecurityIdentifier
You can pipe SecurityIdentifier objects to specify security IDs for local security groups.

## OUTPUTS

### NetLocalGroupPrincipal
Outputs NetLocalGroupPrincipal objects.

## NOTES
Get-NetLocalGroup does not get domain local security groups.

## RELATED LINKS
