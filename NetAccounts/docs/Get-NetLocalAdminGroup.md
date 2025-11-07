---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-NetLocalAdminGroup

## SYNOPSIS
Gets the local Administrators security group.

## SYNTAX

```
Get-NetLocalAdminGroup [[-ComputerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Gets the local Administrators security group from one or more computers.
The local Administrators security group has the security identifier (SID) S-1-5-32-544.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Get-NetLocalAdminGroup
```

Gets the local Administrators security group (SID S-1-5-32-544) on the current computer. This command is equivalent to 'Get-NetLocalGroup -SID S-1-5-32-544'. The command outputs properties of the local Administrators security group.

## PARAMETERS

### -ComputerName
Specifies one or more computer names.
Wildcards are not permitted.
Omit this parameter to get the local Administrators security group on the current computer.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
You can pipe strings to specify computer names.

## OUTPUTS

### NetLocalGroupPrincipal
Outputs NetLocalGroupPrincipal objects.

## NOTES
Get-NetLocalAdminGroup does not get a domain's local Administrators security group.

## RELATED LINKS
