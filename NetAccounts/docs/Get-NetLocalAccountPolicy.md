---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-NetLocalAccountPolicy

## SYNOPSIS
Gets local account and password policy information.

## SYNTAX

```
Get-NetLocalAccountPolicy [[-ComputerName] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
Gets local account and password policy information from one or more computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Get-NetLocalAccountPolicy
```

Gets local account and password policy information from the current computer.

## PARAMETERS

### -ComputerName
Specifies one or more computer names.
Wildcards are not permitted.
Omit this parameter to get local account and password policy information from the current computer.

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

### NetLocalAccountPolicy
Outputs NetLocalAccountPolicy objects.

## NOTES
Get-NetLocalAccountPolicy does not get domain account or password policies.

## RELATED LINKS
