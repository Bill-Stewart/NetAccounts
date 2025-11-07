---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-WellknownNetPrincipal

## SYNOPSIS
Gets well-known principals.

## SYNTAX

### Name (Default)
```
Get-WellknownNetPrincipal [-Name] <String[]> [<CommonParameters>]
```

### SID
```
Get-WellknownNetPrincipal [-SID] <SecurityIdentifier[]> [<CommonParameters>]
```

### DomainAdmins
```
Get-WellknownNetPrincipal [-DomainAdmins] <String[]> [<CommonParameters>]
```

## DESCRIPTION
Gets well-known principals.
Some examples of well-known principals are the built-in Administrators group (SID S-1-5-32-544, type 'BuiltinGroup') and the SYSTEM account (SID S-1-5-18, type 'WellKnown').
For more information, see the Microsoft help topic titled "Well-known SIDs."

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Get-WellknownNetPrincipal "NT AUTHORITY\SYSTEM"
```

Gets the NetPrincipal object for the SYSTEM account (SID S-1-5-18). The command outputs properties of the NetPrincipal object.

### EXAMPLE 2
```powershell
PS > Get-WellknownNetPrincipal -SID S-1-5-32-544
```

Gets the NetPrincipal object for the Administrators built-in group. The command outputs properties of the NetPrincipal object.

### EXAMPLE 3
```powershell
PS > Get-WellknownNetPrincipal -DomainAdmins FABRIKAM
```

Gets the NetPrincipal object for the Domain Admins group in the FABRIKAM domain. The command outputs properties of the NetPrincipal object.

## PARAMETERS

### -DomainAdmins
Gets Domain Admins group principal(s) for the domain name(s) specified by this parameter.

```yaml
Type: String[]
Parameter Sets: DomainAdmins
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Name
Specifies one or more names of well-known principals.
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
Specifies one or more security identifiers (SIDs) of well-known principals.

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
You can pipe strings to specify well-known principal names.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify security IDs for well-known principals.

## OUTPUTS

### NetPrincipal
Outputs NetPrincipal objects.

## NOTES

## RELATED LINKS
