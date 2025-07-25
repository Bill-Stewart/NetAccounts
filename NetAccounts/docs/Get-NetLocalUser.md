---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Get-NetLocalUser

## SYNOPSIS
Gets local user accounts.

## SYNTAX

### Name (Default)
```
Get-NetLocalUser [[-Name] <String[]>] [-ComputerName <String>] [<CommonParameters>]
```

### SID
```
Get-NetLocalUser [-SID] <SecurityIdentifier[]> [-ComputerName <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets local user accounts.
Local user accounts are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Get-NetLocalUser -Name "AdminContoso02"
```
Gets the local user account on the current computer. The command outputs properties of the local user account.

### EXAMPLE 2
```powershell
PS > Get-NetLocalUser -SID "S-1-5-21-9526073513-1762370368-3942940353-500"
```
Gets the local user account by its security identifier (SID). The command outputs properties of the local user account.

## PARAMETERS

### -ComputerName
Specifies the computer name where the local user accounts reside.
Omit this parameter to get local user accounts on the current computer.

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
Specifies one or more names of local user accounts.
Wildcards are not permitted.
Omit this parameter to get all local user accounts.

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SID
Specifies one or more security identifiers (SIDs) of local user accounts.

```yaml
Type: SecurityIdentifier[]
Parameter Sets: SID
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### String
You can pipe strings to specify local user account names.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify security IDs for local user accounts.

## OUTPUTS

### NetLocalUserPrincipal
Outputs NetLocalUserPrincipal objects.

## NOTES

## RELATED LINKS
