---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# New-NetLocalUser

## SYNOPSIS
Creates a local user account.

## SYNTAX

### Password (Default)
```
New-NetLocalUser [-Name] <String> -Password <SecureString> [-AccountExpires <DateTime>]
 [-ChangePasswordAtLogon] [-Description <String>] [-Disabled] [-FullName <String>] [-PasswordNeverExpires]
 [-PasswordRequired] [-UserMayNotChangePassword] [-ProfilePath <String>] [-ScriptPath <String>]
 [-HomeDrive <String>] [-HomeDirectory <String>] [-ComputerName <String>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### NoPassword
```
New-NetLocalUser [-Name] <String> [-NoPassword] [-AccountExpires <DateTime>] [-ChangePasswordAtLogon]
 [-Description <String>] [-Disabled] [-FullName <String>] [-PasswordNeverExpires] [-PasswordRequired]
 [-UserMayNotChangePassword] [-ProfilePath <String>] [-ScriptPath <String>] [-HomeDrive <String>]
 [-HomeDirectory <String>] [-ComputerName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Creates a local user account.
Local user accounts are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > New-NetLocalUser -Name User02 -Description "Description of this account." -NoPassword
```

Creates a new local user account on the current computer.

### EXAMPLE 2
```powershell
PS > New-NetLocalUser User03 -FullName "Third User" -Description "Description of this account."
```

Creates a new local user account on the current computer. The command will prompt for the user account's password.

## PARAMETERS

### -AccountExpires
Specifies the date and time when the local user account expires.
Account expiration specifies a date and time after which the account cannot log on.
If you don't specify this parameter, the account doesn't expire.
Account expiration is different from password expiration.
The account expiration date and time cannot be later than 6 February 2106 6:28:14 UTC.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ChangePasswordAtLogon
Specifies the system will require a password change at the first logon.
The default value for this parameter is $true, so to disable it, you must specify -ChangePasswordAtLogon:$false.
You cannot specify -ChangePasswordAtLogon with -PasswordNeverExpires or -UserMayNotChangePassword.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
Specifies the computer name where to create the local user account.
Omit this parameter to create the local user account on the current computer.

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

### -Description
Specifies a description for the local user account.

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

### -Disabled
Specifies that the local user account will be created in a disabled state.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -FullName
Specifies the full name for the local user account.
The full name differs from the user name of the local user account.

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

### -HomeDirectory
Specifies the path to the user's account's home directory.
You can use '%username%' in this string to represent the user account's name.

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

### -HomeDrive
Specifies a drive that is associated with the UNC path defined by the HomeDirectory property.
The drive letter is specified as '\<Letter\>:' where '\<Letter\>' indicates the letter of the drive to associate.
The drive letter must be a single uppercase letter and the colon is required.

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
Specifies a name for the local user account.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -NoPassword
Specifies to create the local user account without a password.
Note that this will fail if security policies require a password to be specified.

```yaml
Type: SwitchParameter
Parameter Sets: NoPassword
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
Specifies the password for the local user account.
If you omit the -Password and -NoPassword parameters, New-NetLocalUser will prompt for the new local user account's password.

```yaml
Type: SecureString
Parameter Sets: Password
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordNeverExpires
Specifies that the local user account's password does not expire.
You cannot specify both -PasswordNeverExpires and -ChangePasswordAtLogon.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordRequired
Specifies that the local user account requires a password.
The default value for this parameter is $true, so to disable it, you must specify -PasswordRequired:$false.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfilePath
Specifies the path to the local user account's profile.
You can use '%username%' in this string to represent the user account's name.

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

### -ScriptPath
Specifies the path to the local user account's logon script file.

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

### -UserMayNotChangePassword
Specifies that the local user account cannot change the password of the account.
You cannot specify both -UserMayNotChangePassword and -ChangePasswordAtLogon.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
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

### String
You can pipe a string to specify a local user account name.

## OUTPUTS

### NetLocalUserPrincipal
Outputs a NetLocalUserPrincipal object for the local user account.

## NOTES
New-NetLocalUser does not create domain user accounts.

## RELATED LINKS
