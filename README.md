# NetAccounts

**NetAccounts** is a Windows-only PowerShell module for managing local security groups and local user accounts on the current computer and remote computers. You can use it as a replacement for the Microsoft **LocalAccounts** module if you need to manage local security groups and local user accounts on remote computers.

## Copyright and Author

Copyright (C) 2025 by Bill Stewart (bstewart at iname.com)

## License

**NetAccounts** is covered by the MIT license. See `LICENSE.txt` for details.

## Version History

See `history.md`.

## System Requirements

The module requires PowerShell 5.1 or later.

## Installation

The following sections describe how to install the module.

### Install from the PowerShell Gallery

To install the module from the PowerShell gallery, run the following command as an administrator:

    Install-Module NetAccounts -Scope AllUsers

### Install Manually

Create the folder structure for the module and copy the files manually. See the following link for more information:

https://learn.microsoft.com/en-us/powershell/scripting/developer/module/installing-a-powershell-module

## Overview

The **NetAccounts** module is similar in functionality to Microsoft's **LocalAccounts** module, with some notable enhancements. The noun portion of the commands in the **NetAccounts** module use the **Net** prefix to distinguish them from the Microsoft cmdlets, as shown in the following table:

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

The **NetAccounts** module also includes three additional commands that Microsoft's module does not provide:

* **Get-NetLocalAdminGroup** - Gets the local Administrators security group (SID S-1-5-32-544). Equivalent to:

  `Get-NetLocalGroup -SID S-1-5-32-544`

* **Get-NetLocalAdminUser** - Gets the local Administrator user account (RID 500). Equivalent to:

  `Get-NetLocalUser | Where-Object { $_.SID.Value.EndsWith("-500") }`

  (except it's more efficient because you don't need the **Where-Object** filter)

* **Get-WellknownNetPrincipal** - Gets "well-known" principals (group or user accounts). Some examples of well-known group or user accounts are the built-in Administrators group (SID S-1-5-32-544) or the SYSTEM account (SID S-1-5-18). For more information, search Microsoft's documentation for the topic "Well-known SIDs." **Get-WellknownNetPrincipal** can also get the Domain Admins group from a domain by its SID (i.e., it works regardless of language).

## Objects and Types

This section describes the objects and types used in the **NetAccounts** module.

### Objects

The **NetAccounts** module defines three types of objects, as follows:

* `NetPrincipal` - Base type; **Get-NetLocalGroupMember** and **Get-WellknownNetPrincipal** output objects of this type

* `NetLocalGroupPrincipal` - Inherited from the `NetPrincipal` type; represents local security group objects

* `NetLocalUserPrincipal` - Inherited from the `NetPrincipal` type; represents local user objects

The type inheritance means that you can use an inherited type in place of the base type (but not vice-versa). For example, if a parameter requires a `NetPrincipal` object, you can also use a `NetLocalGroupPrincipal` object or a `NetLocalUserPrincipal` object for that parameter. The inverse is not true, however (i.e., if a parameter requires a `NetLocalGroupPrincipal` object, you cannot use a `NetPrincipal` object for that parameter).

### Types

The **NetAccounts** module defines the `NetPrincipalType` enumeration type, which identifies the source of the object's security identifier (SID). The `NetPrincipalType` type can be one of the following values:

* `Unknown` - SID source is unknown

* `Computer` - SID represents a computer account (this type seems to be legacy and no longer used)

* `BuiltinGroup` - SID represents a "built-in" well-known local security group; these groups have the same SID regardless of computer

* `LocalGroup` - SID represents a local security group (known as an "alias" in the Windows API documentation); the `ComputerName` property of the object is where the group exists

* `DomainGroup` - SID represents a domain group; the `AuthorityName` property of the object contains the name of the domain

* `LocalUser` - SID represents a local user account; the `ComputerNaem` property of the object is where the user account exists

* `DomainUser` - SID represents a domain user account; the `AuthorityName` property of the object contains the user account's domain name

* `WellKnown` - SID is a "well-known" SID; these have the same SID regardless of computer

The `Type` property of the `NetPrincipal`, `NetLocalGroupPrincipal`, and `NetLocalUserPrincipal` objects is this type and contains one of the above values.

## Differences from Microsoft's Module

Below are the main differences between the **NetAccounts** module and Microsoft's **LocalAccounts** module:

* This module supports managing local security groups and local users on remote computers using the `-ComputerName` parameter.

* This module includes the following additional commands that are not available in Microsoft's module:

  * **Get-NetLocalAdminGroup**
  * **Get-NetLocalAdminUser**
  * **Get-WellknownNetPrincipal**

* This module works in 32-bit PowerShell.

* This module disallows management of local security groups and/or users on domain controller (DC) servers. This is primarily because "local" accounts on DCs are really domain accounts, and there are other more appropriate tools for managing domain accounts (such as Microsoft's **ActiveDirectory** module).

* **Get-NetLocalGroupMember** does not provide a `-Member` parameter like **Get-LocalGroupMember**. (Workaround: Pipe its output to **Where-Object**.)

* This module cannot determine if local user accounts are connected to Internet-based identities. The underlying reason for this limitation is that that **NetUserGetInfo** API function only supports retrieving this information from local user accounts on the current computer. (Workaround: Use the Microsoft **LocalAccounts** module cmdlets if you need this information about local user accounts on the current computer.) 

* The `DateTime` properties in the `NetLocalUserPrincipal` object do not support timestamps later than 7 February 2106 6:28:14 UTC because the Windows APIs use 32-bit unsigned integers value to represent these timestamps. The APIs calculate these timestamps as the number of seconds since midnight 1 January 1970 UTC. The maximum possible value of a 32-bit unsigned integer is 4294967295 (0xFFFFFFFF in hexadecimal), which the APIs interpret to mean "forever." Using this interpretation, the latest possible timestamp is the value 4294967294 (0xFFFFFFFE in hexadecimal). When we add this number of seconds to midnight 1 January 1970 UTC, we get 7 February 2106 6:28:14 UTC. (This limitation is the unsigned 32-bit variation of the "year 2038 problem," which affects timestamps stored as signed 32-bit integers.)

## Object Comparisons

This section documents the similarities and differences between the Microsoft **LocalAccounts** module's types and objects and the **NetAccounts** module's types and objects.

## How Objects Describe Themselves

The **NetAccounts** and **LocalAccounts** modules differ in the properties that describe the objects themselves, as noted in the following table:

| NetAccounts     | Type               | LocalAccounts     | Type              
| -----------     | ----               | -------------     | ----              
| `Type`          | `NetPrincipalType` | `ObjectClass`     | `String`          
| `AuthorityName` | `String`           | `PrincipalSource` | `PrincipalSource` 

The `Type` property in the **NetAccounts** module's object properties is analgous to the `ObjectClass` property in the **LocalAccounts** module's object properties, and the `AuthorityName` property in the **NetAccounts** module's object properties is analogous to the `PrincipalSource` property in the **LocalAccounts** module's object properties.

## Local Security Groups

The following table compares the **NetAccounts** module `NetLocalGroupPrincipal` object's properties and the Microsoft **LocalAccounts** module `LocalGroup` object's properties.

| `NetLocalGroupPrincipal` | `LocalGroup`  | Type                 | Description
| ------------------------ | ------------  | ----                 | -----------
| `ComputerName`           | (N/A)         | `String`             | Name of computer where group exists
| `Description`            | `Description` | `String`             | Group's description
| `Name`                   | `Name`        | `String`             | Group's name
| `SID`                    | `SID`         | `SecurityIdentifier` | Group's security identifier (SID)

The `LocalGroup` object from the **LocalAccounts** module lacks the `ComputerName` property because the `LocalAccounts` module does not support managing local security groups on a remote computer.

## Comparison of Local User Object Properties

The following table compares the **NetAccounts** module `NetLocalUserPrincipal` object's properties and the Microsoft **LocalAccounts** module `LocalUser` object's properties . The **NetAccounts** module supports more local user account properties than the Microsoft **LocalAccounts** module.

| `NetLocalUserPrincipal` | `LocalUser`              | Type                 | Description
| ----------------------- | -----------              | ----                 | -----------
| `AccountExpires`        | `AccountExpires`         | `DateTime`           | Date and time when the account expires
| `ChangePasswordAtLogon` | (N/A)                    | `Boolean`            | Whether the account's password must change at next logon
| `ComputerName`          | (N/A)                    | `String`             | Computer where account name was resolved
| `Description`           | `Description`            | `String`             | Account's description
| `Enabled`               | `Enabled`                | `Boolean`            | Whether the account is enabled
| `FullName`              | `FullName`               | `String`             | Full name of account
| `HomeDirectory`         | (N/A)                    | `String`             | Path of account's home directory
| `HomeDrive`             | (N/A)                    | `String`             | Drive letter of account's home drive
| `LastLogon`             | `LastLogon`              | `DateTime`           | Date and time of last logon
| `Name`                  | `Name`                   | `String`             | Account's name
| `PasswordChangeable`    | `PasswordChangeableDate` | `DateTime`           | Date and time when the account's password can be changed
| `PasswordExpires`       | `PasswordExpires`        | `DateTime`           | Date and time when the account's password expires
| `PasswordLastSet`       | `PasswordLastSet`        | `DateTime`           | Date and time when the account's password was last set
| `PasswordRequired`      | `PasswordRequired`       | `Boolean`            | Whether the account requires a password
| `ProfilePath`           | (N/A)                    | `String`             | Path of account's user profile
| `ScriptPath`            | (N/A)                    | `String`             | Path of account's logon script
| `SID`                   | `SID`                    | `SecurityIdentifier` | Account's security identifier (SID)
| `UserAccountControl`    | (N/A)                    | `UInt32`             | Value containing flags set on the account
| `UserMayChangePassword` | `UserMayChangePassword`  | `Boolean`            | Whether the account can change its own password

Please note the following differences between the **NetAccounts** module and the Microsoft **LocalAccounts** module:

* The `LocalUser` object from the **LocalAccounts** module lacks the `ComputerName` property because the `LocalAccounts` module does not support managing local user accounts on a remote computer.

* The following properties are not supported in the **LocalAccounts** module: `ChangePasswordAtLogon`, `HomeDirectory`, `HomeDrive`, `ProfilePath`, `ScriptPath`, and `UserAccountControl`.

* The `PasswordChangeable` property in the **NetAccounts** module is named `PasswordChangeableDate` in the **LocalAccounts** module.

* The **NetAccounts** module allows you set the `PasswordRequired` property of a local user account without changing the account's password.
