---
external help file: NetAccounts-help.xml
Module Name: NetAccounts
schema: 2.0.0
---

# Set-NetLocalUser

## SYNOPSIS
Changes local user accounts.

## SYNTAX

### InputObject (Default)
```
Set-NetLocalUser [-InputObject] <NetLocalUserPrincipal> [-AccountExpires <DateTime>] [-AccountNeverExpires]
 [-ChangePasswordAtLogon <Boolean>] [-Description <String>] [-FullName <String>] [-Password <SecureString>]
 [-PasswordNeverExpires <Boolean>] [-PasswordRequired <Boolean>] [-UserMayChangePassword <Boolean>]
 [-ProfilePath <String>] [-ScriptPath <String>] [-HomeDrive <String>] [-HomeDirectory <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

### Name
```
Set-NetLocalUser [-Name] <String> [-AccountExpires <DateTime>] [-AccountNeverExpires]
 [-ChangePasswordAtLogon <Boolean>] [-Description <String>] [-FullName <String>] [-Password <SecureString>]
 [-PasswordNeverExpires <Boolean>] [-PasswordRequired <Boolean>] [-UserMayChangePassword <Boolean>]
 [-ProfilePath <String>] [-ScriptPath <String>] [-HomeDrive <String>] [-HomeDirectory <String>]
 [-ComputerName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### SID
```
Set-NetLocalUser [-SID] <SecurityIdentifier> [-AccountExpires <DateTime>] [-AccountNeverExpires]
 [-ChangePasswordAtLogon <Boolean>] [-Description <String>] [-FullName <String>] [-Password <SecureString>]
 [-PasswordNeverExpires <Boolean>] [-PasswordRequired <Boolean>] [-UserMayChangePassword <Boolean>]
 [-ProfilePath <String>] [-ScriptPath <String>] [-HomeDrive <String>] [-HomeDirectory <String>]
 [-ComputerName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Changes local user accounts.
Local user accounts are specific to individual computers.

## EXAMPLES

### EXAMPLE 1
```powershell
PS > Set-NetLocalUser -Name "Admin07" -Description "Description of this account."
```

Changes the description of a local user account on the current computer.

### EXAMPLE 2
```powershell
PS > Set-NetLocalUser User02 -Password (Read-Host "Password" -AsSecureString)
```

Changes the password for a local user account on the current computer.

## PARAMETERS

### -AccountExpires
Specifies the date and time when the local user account expires.
Account expiration specifies a date and time after which the account cannot log on.
Account expiration is different from password expiration.
You cannot specify both -AccountExpires and -AccountNeverExpires.
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

### -AccountNeverExpires
Specifies that the local user account does not expire.
You cannot specify both -AccountNeverExpires and -AccountExpires.

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

### -ChangePasswordAtLogon
Specifies the system will require a password change at the next logon.
You cannot specify '-ChangePasswordAtLogon $true' with '-PasswordNeverExpires $true' or '-UserMayChangePassword $false'.
If the account's PasswordNeverExpires property is $true, specifying '-ChangePasswordAtLogon -$true' will set the account's PasswordNeverExpires property to $false.
If the account's UserMayChangePassword property is $false, specifying '-ChangePasswordAtLogon $true' will set the account's UserMayChangePassword property to $true.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
Specifies the computer name where the local user account resides.
Omit this parameter change the local user account on the current computer.

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
Specifies the path to the user's home directory.
This can be an empty string ("").
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
Specify an empty string ("") to specify "no home drive."

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

### -InputObject
Specifies the local user account to change.

```yaml
Type: NetLocalUserPrincipal
Parameter Sets: InputObject
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Name
Specifies the name of the local user account to change.
Wildcards are not permitted.

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Password
Specifies the password for the local user account.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordNeverExpires
Specifies whether the local user account's password never expires.
You cannot specify '-PasswordNeverExpires $true' with '-ChangePasswordAtLogon $true'.
If the account's ChangePasswordAtLogon property is $true, specifying '-PasswordNeverExpires $true' will set the account's ChangePasswordAtLogon property to $false.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PasswordRequired
Specifies whether the local user account requires a password.

```yaml
Type: Boolean
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
This can be an empty string ("").
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
This can be an empty string ("").

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

### -SID
Specifies the security identifier (SID) of the user account to change.

```yaml
Type: SecurityIdentifier
Parameter Sets: SID
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -UserMayChangePassword
Specifies whether the local user account can change the password of the account.
You cannot specify '-UserMayChangePassword $false' and '-ChangePasswordAtLogon $true'.
If the account's ChangePasswordAtLogon property is $true, specifying '-UserMayChangePassword $false' will set the account's ChangePasswordAtLogon property to $false.

```yaml
Type: Boolean
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

### NetLocalUserPrincipal
You can pipe NetLocalUserPrincipal objects to specify local user accounts.

### String
You can pipe strings to specify local user account names.

### Security.Principal.SecurityIdentifier
You can pipe SecurityIdentifier objects to specify security IDs of local user accounts.

## OUTPUTS

### None
Returns no output.

## NOTES
Set-NetLocalUser does not change domain user accounts.

## RELATED LINKS
