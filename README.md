<!-- omit in toc -->
# NetAccounts

**NetAccounts** is a Windows-only PowerShell module for managing local security groups, local user accounts, and local account policies on the current computer and remote computers. You can use it as a replacement for the Microsoft **LocalAccounts** module and the **net accounts** command for managing local security groups, local user accounts, and local account policies on remote computers.

<!-- omit in toc -->
## Table of Contents

- [Copyright and Author](#copyright-and-author)
- [License](#license)
- [Version History](#version-history)
- [System Requirements](#system-requirements)
- [Installing and Updating the Module](#installing-and-updating-the-module)
  - [Installing the Module](#installing-the-module)
  - [Updating the Module](#updating-the-module)
- [Module Overview](#module-overview)
- [Differences from Microsoft's Module](#differences-from-microsofts-module)
- [**NetAccounts** Module Objects and Principal Types](#netaccounts-module-objects-and-principal-types)
  - [**NetAccounts** Module Objects](#netaccounts-module-objects)
  - [**NetAccounts** Module Principal Types](#netaccounts-module-principal-types)
- [Differences Between **NetAccounts** and **LocalAccounts** Principal Objects](#differences-between-netaccounts-and-localaccounts-principal-objects)
  - [Base Principal Object Differences](#base-principal-object-differences)
  - [Local Security Group Object Differences](#local-security-group-object-differences)
  - [Local User Account Object Differences](#local-user-account-object-differences)
- [Managing Local Account Policies](#managing-local-account-policies)
- [Finding the Local Account Policies in Group Policy Editor](#finding-the-local-account-policies-in-group-policy-editor)
  - [Local Account Password Policies](#local-account-password-policies)
  - [Local Account Lockout Policies](#local-account-lockout-policies)
  - [Local Account Forced Logoff Policy](#local-account-forced-logoff-policy)

## Copyright and Author

Copyright (C) 2025 by Bill Stewart (bstewart at iname.com)

## License

**NetAccounts** is covered by the MIT license. See `LICENSE.txt` for details.

## Version History

See `history.md`.

## System Requirements

The module requires PowerShell 5.1 or later.

## Installing and Updating the Module

This section describes how to install and update the module.

### Installing the Module

To install the module from the PowerShell gallery, run the following command as an administrator:

    Install-Module NetAccounts -Scope AllUsers

### Updating the Module

To update the module if it is already installed, run the following command as an administrator:

    Update-Module NetAccounts

If the update is successful, you can uninstall previous installed versions using **Uninstall-Module** if no other modules have older versions of the **NetAccounts** module as a dependency.

## Module Overview

The **NetAccounts** module is similar in functionality to Microsoft's **LocalAccounts** module, with some notable enhancements. The noun portion of the commands in the **NetAccounts** module use the *Net* prefix to distinguish them from the equivalent Microsoft cmdlets, as listed in the following table.

| LocalAccounts Module        | NetAccounts Module
| ----------------            | ------------------
| **Add-LocalGroupMember**    | **Add-NetLocalGroupMember**
| **Disable-LocalUser**       | **Disable-NetLocalUser**
| **Enable-LocalUser**        | **Enable-NetLocalUser**
| **Get-LocalGroup**          | **Get-NetLocalGroup**
| **Get-LocalGroupMember**    | **Get-NetLocalGroupMember**
| **Get-LocalUser**           | **Get-NetLocalUser**
| **New-LocalGroup**          | **New-NetLocalGroup**
| **New-LocalUser**           | **New-NetLocalUser**
| **Remove-LocalGroup**       | **Remove-NetLocalGroup**
| **Remove-LocalGroupMember** | **Remove-NetLocalGroupMember**
| **Remove-LocalUser**        | **Remove-NetLocalUser**
| **Rename-LocalGroup**       | **Rename-NetLocalGroup**
| **Rename-LocalUser**        | **Rename-NetLocalUser**
| **Set-LocalGroup**          | **Set-NetLocalGroup**
| **Set-LocalUser**           | **Set-NetLocalUser**

The **NetAccounts** module also includes some additional commands for functionality that Microsoft's module does not provide:

* **Get-NetLocalAccountPolicy** - Gets local account (password, account lockout, and forced logoff) policies.

* **Set-NetLocalAccountPolicy** - Sets local account (password, account lockout, and forced logoff) policies.

* **Get-NetLocalAdminGroup** - Gets the local Administrators security group (SID S-1-5-32-544). Equivalent to:

  `Get-NetLocalGroup -SID S-1-5-32-544`

* **Get-NetLocalAdminUser** - Gets the local Administrator user account (RID 500). Equivalent to:

  `Get-NetLocalUser | Where-Object { $_.SID.Value.EndsWith("-500") }`

  (except it's more efficient because you don't need the **Where-Object** filter)

* **Get-WellknownNetPrincipal** - Gets "well-known" principals (group or user accounts). Some examples of well-known group or user accounts are the built-in Administrators group (SID S-1-5-32-544) or the SYSTEM account (SID S-1-5-18). For more information, search Microsoft's documentation for the topic "Well-known SIDs." **Get-WellknownNetPrincipal** can also get the Domain Admins group from a domain regardless of language.

## Differences from Microsoft's Module

Below are the main differences between the **NetAccounts** module and Microsoft's **LocalAccounts** module:

* This module supports managing non-domain local security groups and local user accounts on remote computers using the `-ComputerName` parameter. Microsoft's **LocalAccounts** module is only able to manage local security groups and local user accounts on the current computer; it cannot manage local security groups or local user accounts on remote computers.

* This module supports management of local account policies on the current as well as remote computers. Microsoft's **LocalAccounts** module does not support management of these policies.

* This module includes the following additional commands that are have no equivalent in Microsoft's module:

  * **Get-NetLocalAccountPolicy**
  * **Get-NetLocalAdminGroup**
  * **Get-NetLocalAdminUser**
  * **Get-WellknownNetPrincipal**
  * **Set-NetLocalAccountPolicy**

* This module works in 32-bit PowerShell.

* This module disallows management of local security groups, users, and account policies on Active Directory domain controller (DC) servers. This is primarily because "local" accounts and policies on DCs are really domain accounts and policies, and there are other more appropriate tools for managing domain accounts and policies.

* **Get-NetLocalGroupMember** does not provide a `-Member` parameter like **Get-LocalGroupMember**. (Workaround: Pipe its output to **Where-Object**.)

* This module cannot determine if local user accounts are connected to Internet-based identities. The underlying reason for this limitation is that the **NetUserGetInfo** Windows API function only supports retrieving this information from local user accounts on the current computer. (Workaround: Use the Microsoft **LocalAccounts** module cmdlets if you need this information about local user accounts on the current computer.)

* The `DateTime` properties in the `NetLocalUserPrincipal` object do not support timestamps later than 7 February 2106 6:28:14 UTC because the Windows APIs use 32-bit unsigned integers value to represent these timestamps. The APIs calculate these timestamps as the number of seconds since midnight 1 January 1970 UTC. The maximum possible value of a 32-bit unsigned integer is 4294967295 (0xFFFFFFFF in hexadecimal), which the APIs interpret as an indefinite duration. Using this interpretation, the latest possible timestamp is the value 4294967294 (0xFFFFFFFE in hexadecimal). When we add this number of seconds to midnight 1 January 1970 UTC, we get 7 February 2106 6:28:14 UTC. (This limitation is the unsigned 32-bit integer variation of the "year 2038 problem," which affects timestamps stored as signed 32-bit integers.)

## **NetAccounts** Module Objects and Principal Types

This section describes the objects and principal types used by the **NetAccounts** module. (As used in this documentation, a _principal_ is a group or user account.)

### **NetAccounts** Module Objects

The following table compares the objects used by the **NetAccounts** module and the equivalent objects used by the Microsoft **LocalAccounts** module.

| **NetAccounts** Module   | **LocalAccounts** Module | Description
| -----------------------  | ------------------------ | -----------
| `NetLocalAccountPolicy`  | N/A                      | Local account policies
| `NetPrincipal`           | `LocalPrincipal`         | Base principal type
| `NetLocalGroupPrincipal` | `LocalGroup`             | Local security group type; inherited from base principal type
| `NetLocalUserPrincipal`  | `LocalUser`              | Local user account type; inherited from base principal type

Note the following:

* The `NetLocalAccountPolicy` object has no equivalent in the Microsoft **LocalAccounts** module because the **LocalAccounts** module cannot manage local account policies.

* An inherited type contains all the properties from its base type and adds additional properties that differentiate it from the base type. For example, the `NetLocalUserPrincipal` object has all of the properties of the `NetPrincipal` object as well as additional properties that differentiate it from the `NetPrincipal` Object.

* You can use an inherited type in place of the base type, but not vice-versa. For example, if a parameter requires a `NetPrincipal` object, you can also use a `NetLocalGroupPrincipal` object or a `NetLocalUserPrincipal` object for that parameter. The inverse is not true, however (i.e., if a parameter requires a `NetLocalGroupPrincipal` object, you cannot use a `NetPrincipal` object for that parameter).

### **NetAccounts** Module Principal Types

The **NetAccounts** module defines the `NetPrincipalType` enumeration type, which identifies the source of a principal object's security identifier (SID). The `NetPrincipalType` type can be one of the following values:

* `Unknown` - SID source is unknown

* `Computer` - SID represents a computer account (this type seems to be legacy and no longer used)

* `BuiltinGroup` - SID represents a "built-in" well-known local security group; these groups have the same SID regardless of computer

* `LocalGroup` - SID represents a local security group (known as an "alias" in the Windows API documentation)

* `DomainGroup` - SID represents a domain group

* `LocalUser` - SID represents a local user account

* `DomainUser` - SID represents a domain user account

* `WellKnown` - SID is a "well-known" SID; these have the same SID regardless of computer

The `Type` property of the `NetPrincipal` object (and inherited by the `NetLocalGroupPrincipal` and `NetLocalUserPrincipal` objects) is this type and contains one of the above values.

## Differences Between **NetAccounts** and **LocalAccounts** Principal Objects

This section describes the differences between the principal objects used by the **NetAccounts** and the Microsoft **LocalAccounts** modules.

### Base Principal Object Differences

As noted in [**NetAccounts** Module Objects](#netaccounts-module-objects) (above), the **NetAccounts** module uses the `NetPrincipal` object type as its base principal type, and the Microsoft **LocalAccounts** module uses the `LocalPrincipal` object type as its base principal type.  The following table compares the properties of the base principal objects used by both modules.

| `NetPrincipal` Property | Property Type      | `LocalPrincipal` Property | Property Type
| ----------------------- | -------------      | ------------------------- | -------------
| `Name`                  | `String`           | `Name`                    | `String`
| `ComputerName`          | `String`           | N/A                       | N/A
| `Type`                  | `NetPrincipalType` | `ObjectClass`             | `String`
| `AuthorityName`         | `String`           | `PrincipalSource`         | `PrincipalSource`

Note the following:

* The `Name` property is the same for both object types.

* The `LocalPrincipal` object in Microsoft's `LocalAccounts` module lacks a `ComputerName` property because the `LocalAccounts` module does not support managing local security groups or local user accounts on remote computers.

* The `Type` property in the `NetAccounts` module is roughly analogous to the `ObjectClass` property in Microsoft's `LocalAccounts` module and will be one of the values described in [**NetAccounts** Module Principal Types](#netaccounts-module-principal-types) (above).

* The `AuthorityName` property in the `NetAccounts` module is roughly analogous to the `PrincipalSource` property in Microsoft's `LocalAccounts` module. The values of the `AuthorityName` and `ComputerName` properties depend on the value of the `Type` property, as described in the following table.

  | `Type`         | `AuthorityName` | `ComputerName`              | Description
  | ------         | --------------- | --------------              | -----------
  | `BuiltinGroup` | **BUILTIN**     | Computer where group exists | "Built-in" local security group
  | `LocalGroup`   | Computer name   | Computer where group exists | Local security group
  | `LocalUser`    | Computer name   | Computer where user exists  | Local user account
  | `DomainGroup`  | Domain name     | Computer that resolved name | Domain group
  | `DomainUser`   | Domain name     | Computer that resolved name | Domain user account
  | `WellKnown`    | Varies          | Computer that resolved name | "Well-known" account

> NOTE: These property comparisons also apply to the inherited object types.

### Local Security Group Object Differences

The **NetAccounts** module's `NetLocalGroupPrincipal` object and the **LocalAccounts** module's `LocalGroup` object are the same except for the differences inherited from their respective base principal object types as described in [Base Principal Object Differences](#base-principal-object-differences) (above).

### Local User Account Object Differences

In addition to the differences inherited from their respective base principal object types as described in [Base Principal Object Differences](#base-principal-object-differences) (above), the following table lists the other differences between the **NetAccounts** module's `NetLocalUserPrincipal` object and the **LocalAccounts** module's `LocalUser` object.

| `NetLocalUserPrincipal` Property | Property Type | `LocalUser` Property     | Property Type | Description
| -------------------------------- | ------------- | --------------------     | ------------- | -----------
| `ChangePasswordAtLogon`          | `Boolean`     | N/A                      | N/A           | Indicates whether the account's password must be changed at next logon  
| `HomeDirectory`                  | `String`      | N/A                      | N/A           | Path of account's home directory
| `HomeDrive`                      | `String`      | N/A                      | N/A           | Drive letter of account's home drive
| `PasswordChangeable`             | `DateTime`    | `PasswordChangeableDate` | `DateTime`    | When the account's password can be changed
| `PasswordRequired`               | `Boolean`     | `PasswordRequred`        | `Boolean`     | Same in both modules
| `ProfilePath`                    | `String`      | N/A                      | N/A           | Path of account's user profile
| `ScriptPath`                     | `String`      | N/A                      | N/A           | Path of account's logon script
| `UserAccountControl`             | `UInt32`      | N/A                      | N/A           | Value containing flags set on the account

Note the following:

* The following properties do not exist in the **LocalAccounts** module: `ChangePasswordAtLogon`, `HomeDirectory`, `HomeDrive`, `ProfilePath`, `ScriptPath`, and `UserAccountControl`.

* The `PasswordChangeable` property in the **NetAccounts** module is named `PasswordChangeableDate` in the **LocalAccounts** module.

* The `PasswordRequired` property is the same in both modules, except that the **NetAccounts** module allows you set this property without changing the account's password.

## Managing Local Account Policies

The **NetAccounts** module allows management of local account (password, account lockout, and forced logoff) policies on local and remote computers.

**Get-NetLocalAccountPolicy** outputs `NetLocalAccountPolicy` objects, the properties of which are described in the following table.

| Property                    | Type      | Description
| --------                    | ----      | -----------
| `ComputerName`              | `String`  | Computer where the local account policies are configured
| `PasswordsExpire`           | `Boolean` | Indicates whether passwords expire
| `MaximumPasswordAgeDays`    | `UInt32`  | Maximum password age
| `MinimumPasswordLength`     | `UInt32`  | Minimum password length
| `MinimumPasswordAgeDays`    | `UInt32`  | Minimum password age
| `PasswordHistoryCount`      | `UInt32`  | Number of passwords retained in password history
| `AccountLockout`            | `Boolean` | Indicates whether accounts lock out
| `LockoutThresholdCount`     | `UInt32`  | Number of failed logon attempts that trigger account lockout
| `LockoutDurationMinutes`    | `UInt32`  | How long account lockouts should last
| `LockoutObservationMinutes` | `UInt32`  | How long after a failed logon attempt before the failed logon attempt counter is reset to 0
| `ForceLogoff`               | `Boolean` | Indicates whether user accounts' Server Message Block (SMB) network client sessions are forcibly disconnected after valid logon hours
| `ForceLogoffMinutes`        | `UInt32`  | How long after the end of valid logon hours user accounts' SMB network client sessions are forcibly disconnected

**Set-NetLocalAccountPolicy** configures these local account policies.

**Get-NetLocalAccountPolicy** and **Set-NetLocalAccountPolicy** are roughly analogous to the legacy `net accounts` command, with the following improvements:

* `Get-NetLocalAccountPolicy` outputs objects with typed properties; `net accounts` output is text and must be manually parsed.

* `Get-NetLocalAccountPolicy` can get local account policies from a remote computer; `net accounts` cannot.

* `Set-NetLocalAccountPolicy` can set local account lockout properties; `net accounts` cannot.

* `Set-NetLocalAccountPolicy` can set local account policies on a remote computer; `net accounts` cannot.

## Finding the Local Account Policies in Group Policy Editor

You can find the local account policies in the Group Policy Editor under **Computer Configuration/Windows Settings/Security Settings**.

> NOTE: The locations and names of the local account policies in the Group Policy Editor might be labeled differentiy in different versions of the operating system.

### Local Account Password Policies

The following table lists where to find the local account password policies in the Group Policy Editor.

| Password Policy Setting  | Group Policy Editor Location
| ------------------------ | ----------------------------
| `PasswordHistoryCount`   | **Account Policies/Password Policy/Enforce password history**
| `MaximumPasswordAgeDays` | **Account Policies/Password Policy/Maximum password age**
| `MinimumPasswordAgeDays` | **Account Policies/Password Policy/Minimum password age**
| `MinimumPasswordLength`  | **Account Policies/Password Policy/Minimum password length**

The `PasswordsExpire` property in the `NetLocalAccountPolicy` object will be false if the maximum password age setting is equal to zero, or true if the maximum password age is greater than zero.

To disable local account password expiration, use:

    Set-NetLocalAccountPolicy -PasswordsNeverExpire

### Local Account Lockout Policies

The following table lists where to find the local account lockout policies in the Group Policy Editor.

| Account Lockout Policy Setting | Group Policy Editor Location
| ------------------------------ | ----------------------------
| `LockoutDurationMinutes`       | **Account Policies/Account Lockout Policy/Account lockout duration**
| `LockoutThresholdCount`        | **Account Policies/Account Lockout Policy/Account lockout threshold**
| `LockoutObservationMinutes`    | **Account Policies/Account Lockout Policy/Reset account lockout counter after**

The `AccountLockout` property in the `NetLocalAccountPolicy` object will be false if the lockout threshold is equal to zero, or true if the lockout threshold is greater than zero.

To disable local account lockouts, use:

    Set-NetLocalAccountPolicy -NoAccountLockout

### Local Account Forced Logoff Policy

The local account forced logoff policy corresponds to the following setting in the Group Policy Editor:

**Local Policies/Security Options/Network security: Force logoff when logon hours expire**

Enabling this policy in the Group Policy Editor is equivalent to:

    Set-NetLocalAccountPolicy -ForceLogoffMinutes 0

Conversely, disabling this policy in the Group Policy Editor is equivalent to:

    Set-NetLocalAccountPolicy -NoForceLogoff

The `ForceLogoff` property in the `NetLocalAccountPolicy` object will be false if the `ForceLogoffMinutes` property is null, or true if the `ForceLogoffMinutes` property is 0 or greater.

> NOTE: This Group Policy setting will only show as enabled if the `ForceLogoffMinutes` property is zero. If the property is non-zero, the Group Policy setting will show as disabled, even though the policy is in effect. If you want to enable the policy, it is recommended to use an argument of **0** for the **Set-NetLocalAccountPolicy** `-ForceLogoffMinutes` parameter in order to maintain consistency.
