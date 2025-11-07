---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-NetLocalAdminUser

## SYNOPSIS
Gets the local Administrator user account.

## SYNTAX

```
Get-NetLocalAdminUser [[-ComputerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Gets the local Administrator user account from one or more computers.
The security identifier (SID) of a computer's local Administrator user account is the computer's SID with the relative identifier (RID) 500.

## EXAMPLES

### EXAMPLE 1
```powershell
Get-NetLocalAdminUser
```

Gets the local Administrator user account (RID 500) on the current computer. This command is equivalent to 'Get-NetLocalUser | Where-Object { $_.SID.Value.EndsWith("-500") }', except that it is more efficient because it retrieves the local Administrator user account on the computer directly without needing the Where-Object filter. The command outputs properties of the local Administrator user account.

## PARAMETERS

### -ComputerName
Specifies one or more computer names.
Wildcards are not permitted.
Omit this parameter to get the local Administrator user account on the current computer.

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

### NetLocalUserPrincipal
Outputs NetLocalUserPrincipal objects.

## NOTES
Get-NetLocalAdminUser does not get a domain's Administrator user account.

## RELATED LINKS
