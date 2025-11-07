ConvertFrom-StringData @'
AddLocalGroupMember = Add member '{0}'
RemoveLocalGroupMember = Remove member '{0}'
DisableLocalUser = Disable local user account
EnableLocalUser = Enable local user account
NewLocalGroup = Create local security group '{0}'
NewLocalUser = Create local user account '{0}'
RemoveLocalGroup = Remove local security group
RemoveLocalUser = Remove local user account
RenameLocalGroup = Rename local security group to '{0}'
RenameLocalUser = Rename local user account to '{0}'
SetLocalGroup = Modify local security group
SetLocalUserParamErrorAccountExpiration = You cannot specify both -AccountExpires and -AccountNeverExpires.
SetLocalUserParamErrorPassword = You cannot specify "-ChangePasswordAtLogon $true" with either "-PasswordNeverExpires $true" or "-UserMayChangePassword $false".
SetLocalUser = Modify local user account
SetLocalAccountPolicyForceLogoffNonZero = A non-zero value for the -ForceLogoffMinutes parameter will not reflect the policy accurately in the Group Policy Editor. It is recommended to use a value of 0 for this parameter.
SetLocalAccountPolicyParamErrorLockout = -LockoutDurationMinutes must either be 0 or greater than or equal to -LockoutObservationMinutes.
SetLocalAccountPolicy = Modify local account policy
'@
