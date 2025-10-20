---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Set-NetLocalAccountPolicy

## SYNOPSIS
Sets account and password policy information.

## SYNTAX

### NoAccountLockout
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] [-NoAccountLockout] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### AccountLockout
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] -LockoutDurationMinutes <Int32>
 -LockoutObservationMinutes <Int32> -LockoutThresholdCount <Int32> [-WhatIf] [-Confirm] [<CommonParameters>]
```

### MinimumPasswordLength
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] -MinimumPasswordLength <Int32> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PasswordsNeverExpire
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] [-PasswordsNeverExpire] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### MaximumPasswordAge
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] -MaximumPasswordAgeDays <Int32> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### MinimumPasswordAge
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] -MinimumPasswordAgeDays <Int32> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### PasswordHistoryCount
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] -PasswordHistoryCount <Int32> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### NoForceLogoff
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] [-NoForceLogoff] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### ForceLogoff
```
Set-NetLocalAccountPolicy [[-ComputerName] <String[]>] -ForceLogoffMinutes <Int32> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Sets account and password policy information on one or more computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Set-NetLocalAccountPolicy -PasswordsNeverExpire
```

Sets passwords not to expire in the password policy on the current computer. The command will prompt for confirmation.

### EXAMPLE 2
```
PS > Set-NetLocalAccountPolicy -LockoutThresholdCount 5 -LockoutDurationMinutes 2 -LockoutObservationMinutes 1 -Confirm:$false
```

For the current computer, specifies that accounts lock out after 5 invalid attempts, remain locked for 2 minutes, and that 1 minute can elapse between any two failed logon attempts before lockout occurs. The command will not prompt for confirmation.

## PARAMETERS

### -ComputerName
Specifies one or more computer names.
Wildcards are not permitted.
Omit this parameter to set account and password policy information for the current computer.

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

### -ForceLogoffMinutes
Specifies the number of minutes after the end of the user's logon hours after which the user is logged off. Valid values for this parameter are 0 through 999. A value of zero indicates that the user will be logged off immediately when the user's logon hours expire. Specify -NoForceLogoff instead of this parameter to disable forced logoffs.

```yaml
Type: Int32
Parameter Sets: ForceLogoff
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LockoutDurationMinutes
Specifies the number of minutes a locked account remains locked before it is automatically unlocked. Valid values are 0 through 99999. Specify zero if the account is to remain locked out indefinitely until an administrator unlocks it. This parameter must be greater than or equal to the -LockoutObservationMinutes parameter. A value of zero is not recommended due to potential denial-of-service.

```yaml
Type: Int32
Parameter Sets: AccountLockout
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LockoutObservationMinutes
Specifies the number of minutes that can elapse between any two failed logon attempts before lockout occurs. Valid values are 1 through 99999. This parameter must be less than or equal to the -LockoutDurationMinutes parameter.

```yaml
Type: Int32
Parameter Sets: AccountLockout
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LockoutThresholdCount
Specifies the number of invalid password authentications that can occur before an account is locked out. Valid values for this parameter are 1 through 999. Specify -NoAccountLockout instead of this parameter to disable account lockouts.

```yaml
Type: Int32
Parameter Sets: AccountLockout
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumPasswordAgeDays
Specifies the maximum number of days a password can be used before it expires. Valid values for this parameter are 1 through 999. This parameter must be greater than or equal to the minimum password age. Specify -PasswordsNeverExpire instead of this parameter to disable password expiration.

```yaml
Type: Int32
Parameter Sets: MaximumPasswordAge
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumPasswordAgeDays
Specifies the minimum number of days that can elapse between the time a password changes and when it can be changed again. Valid values for this paramter are 0 through 999. A value of zero indicates that no delay is required between password changes. This parameter must be less than or equal to the maximum password age.

```yaml
Type: Int32
Parameter Sets: MinimumPasswordAge
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumPasswordLength
Specifies the minimum allowable password length. Valid values for this parameter are 0 through 14.

```yaml
Type: Int32
Parameter Sets: MinimumPasswordLength
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoAccountLockout
Specifies that accounts do not lock out, regardless of how many invalid authentications occur.

```yaml
Type: SwitchParameter
Parameter Sets: NoAccountLockout
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoForceLogoff
Specifies that accounts are not forced to log off when logon hours expire.

```yaml
Type: SwitchParameter
Parameter Sets: NoForceLogoff
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordHistoryCount
Specifies the number of unique new passwords that have to be associated with a user account before an old password can be reused. Valid values for this parameter are 0 through 8. Specify zero to disable the password history (i.e., old passwords can be reused immediately).

```yaml
Type: Int32
Parameter Sets: PasswordHistoryCount
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordsNeverExpire
Specifies that passwords do not expire.

```yaml
Type: SwitchParameter
Parameter Sets: PasswordsNeverExpire
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

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
Shows what would happen if the cmdlet runs. The cmdlet is not run.

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

### String
You can pipe strings to specify computer names.

## OUTPUTS

### None
Returns no output.

## NOTES
Set-NetLocalAccountPolicy prompts for confirmation by default. To bypass the confirmation prompt, specify '-Confirm:$false'.

## RELATED LINKS
