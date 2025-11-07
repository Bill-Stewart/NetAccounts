# NetAccounts PowerShell Module Version History

## 0.0.5 (2025-11-07)

* **Add-NetLocalGroupMember** now prevents adding a local security group as a member of another local security group. (Although the Windows API allows the operation, there's no point in doing so because local security group nesting is not supported.)

* The **Set-NetLocalAccountPolicy -PasswordHistoryCount** parameter has been updated to allow up to 24 passwords in the password history. (The previous limit of 8 was set due to outdated Windows API documentation.)

* **Get-NetLocalAccountPolicy** now correctly retrieves an "indefinite" account lockout duration as 0 (as in the Group Policy Editor).

* The **Set-NetLocalAccountPolicy -LockoutDurationMinutes** parameter now correctly accepts a value of 0 to set an "indefinite" account lockout duration (as in the Group Policy Editor).

* For better alignment with the **net accounts /forcelogoff** command, the maximum value for the **Set-NetLocalAccountPolicy -ForceLogoffMinutes** parameter has been extended from 999 to 71539200 minutes (828 days). As noted below, it is recommended to use a value of 0 for this parameter.

* If you use **Set-NetLocalAccountPolicy -ForceLogoffMinutes** with an argument greater than 0, there is now a warning message that a non-zero value for this policy will not reflect it accurately in the Group Policy Editor and that 0 is the recommended value.

* Updated the description for the **Set-NetLocalAccountPolicy -ForceLogoffMinutes** parameter with verbiage similar to the Group Policy Editor to more accurately describe what this policy setting actually does: It forcibly disconnects user accounts' SMB (Server Message Block) network client sessions after valid logon hours.

* Added the `AccountLockout` property to the `NetLocalAccountPolicy` object.

* The `LockoutThresholdCount` property in the `NetLocalAccountPolicy` object is now null (rather than 0) if the `AccountLockout` property is false.

* Expanded the documentation and improved the help.

## 0.0.4 (2025-10-27)

* Fixed error message regression when unable to set user properties.

* Created separate messages file for improved localization.

## 0.0.3 (2025-10-20)

* Added **Get-NetLocalAccountPolicy** and **Set-NetLocalAccountPolicy**.

* Added `NetLocalAccountPolicy` object type.

## 0.0.2 (2025-07-25)

* Initial version.
