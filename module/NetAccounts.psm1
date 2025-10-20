<#

NetAccounts.psm1 - Written by Bill Stewart (bstewart AT iname.com)


Background
==========

This script module is a replacement (mostly) for Microsoft's LocalAccounts
PowerShell module. The main reason for developing this module was to add the
-ComputerName parameter to allow management of local security groups and local
user accounts on remote machines.

Th module should have acceptable performance because it uses .NET P/Invoke to
execute the Windows APIs directly.

See README.md for more details.


System Requirements
===================

Windows platform; PowerShell 5.1 or later


Command Names
=============

This module uses the same set of commands as the Microsoft LocalAccounts
module, with the exception that this module uses the "Net" prefix for each
noun, as follows:

LocalAccounts Module     This Module
--------------------     -----------
Add-LocalGroupMember     Add-NetLocalGroupMember
Disable-LocalUser        Disable-NetLocalUser
Enable-LocalUser         Enable-NetLocalUser
Get-LocalGroup           Get-NetLocalGroup
Get-LocalGroupMember     Get-NetLocalGroupMember
Get-LocalUser            Get-NetLocalUser
New-LocalGroup           New-NetLocalGroup
New-LocalUser            New-NetLocalUser
Remove-LocalGroup        Remove-NetLocalGroup
Remove-LocalGroupMember  Remove-NetLocalGroupMember
Remove-LocalUser         Remove-NetLocalUser
Rename-LocalGroup        Rename-NetLocalGroup
Rename-LocalUser         Rename-NetLocalUser
Set-LocalGroup           Set-NetLocalGroup
Set-LocalUser            Set-NetLocalUser

The Windows API functions that modify users and local security groups all use
"Net" in their names (NetLocalGroupAdd, NetUserGetInfo, etc.), so the "Net"
prefix seemed appropriate. The "Net" prefix also suggests they work "over the
network" (remotely), which differentiates this module from Microsoft's module.

This module also includes some additional commands that Microsoft's module
does not provide:

* Get-NetLocalAccountPolicy and Set-NetLocalAccountPolicy - Self-explanatory.

* Get-NetLocalAdminGroup - Gets the local Administrators security group (SID
  S-1-5-32-544). Equivalent to:
  Get-NetLocalGroup -SID S-1-5-32-544

* Get-NetLocalAdminUser - Gets the local Administrator user account (RID 500).
  Equivalent to:
  Get-NetLocalUser | Where-Object { $_.SID.Value.EndsWith("-500") }
  (except it's more efficient because you don't need the Where-Object filter)

* Get-WellknownNetPrincipal - Gets NetPrincipal objects for "well-known"
  principals. For example, Administrators (S-1-5-32-544) or SYSTEM (S-1-5-18).
  For more information, search Microsoft's documentation for the topic
  "Well-known SIDs."


Test Mode
=========

This module supports a test mode that outputs the Windows API function calls
and parameters using Write-Host. If test mode is enabled, the module makes no
changes to local security groups or local user accounts. This is really only
useful for debugging purposes.

For example, suppose you run this command with test mode enabled:

PS C:\> New-NetLocalUser testuser -NoPassword

The Write-Host output for this command will look like the following:

TEST: NetUserAdd <computername>
      USER_INFO_4.usri4_name = testuser
      USER_INFO_4.usri4_password =
      USER_INFO_4.usri4_home_dir =
      USER_INFO_4.usri4_comment =
      USER_INFO_4.usri4_flags = 0x00000001
      USER_INFO_4.usri4_script_path =
      USER_INFO_4.usri4_full_name =
      USER_INFO_4.usri4_acct_expires = 0xFFFFFFFF
      USER_INFO_4.usri4_max_storage = 0xFFFFFFFF
      USER_INFO_4.usri4_primary_group_id = 0x00000201
      USER_INFO_4.usri4_profile =
      USER_INFO_4.usri4_home_dir_drive =
      USER_INFO_4.usri4_password_expired = 0x00000001

The test output shows that the code uses the NetUserAdd Windows API with the
appropriate values set in the USER_INFO_4 structure to create the local user
account on the specified computer. (See the Microsoft documentation for more
information on the Windows API.)

To enable test mode, set the PSMODULE_NETACCOUNTS_TESTMODE environment variable
to 1. Removing the variable (or setting it to any value other than 1) disables
test mode.

#>

#requires -version 5.1

if ( [Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT ) {
  throw "Windows platform required"
}

# Write-Host color when test mode is enabled
$TEST_COLOR = [ConsoleColor]::Yellow

# General Win32 constants
$DWORD_MAX = [BitConverter]::ToUInt32([BitConverter]::GetBytes(-1),0)
$MAX_PREFERRED_LENGTH      = $DWORD_MAX
$TIMEQ_FOREVER             = $DWORD_MAX
$USER_MAXSTORAGE_UNLIMITED = $DWORD_MAX

# Win32 error codes
$ERROR_SUCCESS              = 0                    # The operation completed successfully
$ERROR_ACCESS_DENIED        = 5                    # Access is denied
$ERROR_NOT_SUPPORTED        = 50          # 0x32   # The request is not supported
$ERROR_BAD_NETPATH          = 53          # 0x35   # The network path was not found
$ERROR_INVALID_PARAMETER    = 87          # 0x57   # The parameter is incorrect
$ERROR_INSUFFICIENT_BUFFER  = 122         # 0x7A   # The data area passed to a system call is too small
$ERROR_INVALID_DOMAINNAME   = 1212        # 0x4BC  # The format of the specified domain name is invalid
$ERROR_NONE_MAPPED          = 1332        # 0x534  # No mapping between account names and security IDs was done
$ERROR_NO_SUCH_DOMAIN       = 1355        # 0x54B  # The specified domain either does not exist or could not be contacted
$ERROR_MEMBER_NOT_IN_ALIAS  = 1377        # 0x561  # The specified account name is not a member of the group
$ERROR_MEMBER_IN_ALIAS      = 1378        # 0x562  # The specified account name is already a member of the group
$RPC_S_INVALID_NET_ADDR     = 1707        # 0x6AB  # The network address is invalid
$ERROR_INVALID_TIME         = 1901        # 0x76D  # The specified time is invalid
$NERR_GroupNotFound         = 2220        # 0x8AC  # The group name could not be found
$NERR_UserNotFound          = 2221        # 0x8AD  # The user name could not be found
$NERR_PasswordTooShort      = 2245        # 0x8C5  # The password does not meet the password policy requirements...
$CO_E_INVALIDSID            = 0x8001012D           # One of the security identifiers provided by the user was invalid
$CO_E_NOMATCHINGSIDFOUND    = 0x8001012F           # Unable to find a security identifier that corresponds to a trustee string provided by the user
$CO_E_NOMATCHINGNAMEFOUND   = 0x80010131           # Unable to find a trustee name that corresponds to a security identifier provided by the user

# Win32 user account constants and flags
$DOMAIN_GROUP_RID_USERS = 513    # 0x201
$UF_SCRIPT              = 1
$UF_ACCOUNTDISABLE      = 2
$UF_PASSWD_NOTREQD      = 32     # 0x20
$UF_PASSWD_CANT_CHANGE  = 64     # 0x40
$UF_NORMAL_ACCOUNT      = 512    # 0x200
$UF_DONT_EXPIRE_PASSWD  = 65536  # 0x10000

# DsGetDcName flags
$DS_DIRECTORY_SERVICE_REQUIRED = 0x00000010
$DS_IP_REQUIRED                = 0x00000200

# NetServerGetInfo flags
$SV_TYPE_DOMAIN_CTRL    = 8
$SV_TYPE_DOMAIN_BAKCTRL = 16  # 0x10

# Other constants
$MAX_OBJECT_NAME_LENGTH = 512

# Maps Win32 error codes to error categories
$ErrorCodeCategory = @{
  $ERROR_ACCESS_DENIED        = [Management.Automation.ErrorCategory]::PermissionDenied
  $ERROR_NOT_SUPPORTED        = [Management.Automation.ErrorCategory]::OperationStopped
  $ERROR_BAD_NETPATH          = [Management.Automation.ErrorCategory]::ResourceUnavailable
  $ERROR_INVALID_PARAMETER    = [Management.Automation.ErrorCategory]::InvalidArgument
  $ERROR_INSUFFICIENT_BUFFER  = [Management.Automation.ErrorCategory]::LimitsExceeded
  $ERROR_INVALID_DOMAINNAME   = [Management.Automation.ErrorCategory]::InvalidArgument
  $ERROR_NONE_MAPPED          = [Management.Automation.ErrorCategory]::ObjectNotFound
  $ERROR_NO_SUCH_DOMAIN       = [Management.Automation.ErrorCategory]::ResourceUnavailable
  $ERROR_MEMBER_NOT_IN_ALIAS  = [Management.Automation.ErrorCategory]::ObjectNotFound
  $ERROR_MEMBER_IN_ALIAS      = [Management.Automation.ErrorCategory]::ResourceExists
  $RPC_S_INVALID_NET_ADDR     = [Management.Automation.ErrorCategory]::ResourceUnavailable
  $ERROR_INVALID_TIME         = [Management.Automation.ErrorCategory]::InvalidArgument
  $NERR_GroupNotFound         = [Management.Automation.ErrorCategory]::ObjectNotFound
  $NERR_UserNotFound          = [Management.Automation.ErrorCategory]::ObjectNotFound
  $NERR_PasswordTooShort      = [Management.Automation.ErrorCategory]::InvalidArgument
  $CO_E_INVALIDSID            = [Management.Automation.ErrorCategory]::ObjectNotFound
  $CO_E_NOMATCHINGSIDFOUND    = [Management.Automation.ErrorCategory]::ObjectNotFound
  $CO_E_NOMATCHINGNAMEFOUND   = [Management.Automation.ErrorCategory]::ObjectNotFound
}

# Can't set DateTimes later than this (32-bit unsigned integer overflow)
$LatestDateTimeOffset = New-Object DateTimeOffset(2106,2,7,6,28,14,(New-Object TimeSpan(0)))


Add-Type -MemberDefinition @"
//=============================================================================
// General
//=============================================================================

// Win32 API values
private static uint UF_DONT_EXPIRE_PASSWD = 0x10000;
private static uint TIMEQ_FOREVER = System.BitConverter.ToUInt32(System.BitConverter.GetBytes(-1), 0);

// RID for "BUILTIN" local security groups
private static System.Security.Principal.SecurityIdentifier SECURITY_BUILTIN_DOMAIN_RID =
  new System.Security.Principal.SecurityIdentifier("S-1-5-32");

// Latest possible UInt32 timestamp ("year 2106" problem)
private static DateTimeOffset LatestDateTimeOffset =
  new DateTimeOffset(2106, 2, 7, 6, 28, 14, new TimeSpan(0));

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+SID_NAME_USE]
// This enum type is returned by LookupAccountName and LookupAccountSid
public enum SID_NAME_USE
{
  SidTypeUser = 1,
  SidTypeGroup,
  SidTypeDomain,
  SidTypeAlias,           // alias == a local security group
  SidTypeWellKnownGroup,
  SidTypeDeletedAccount,
  SidTypeInvalid,
  SidTypeUnknown,
  SidTypeComputer,
  SidTypeLabel,
  SidTypeLogonSession
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetPrincipalType]
// This enum type is used by Net[Local[Group|User]]Principal objects
public enum NetPrincipalType
{
  Unknown = 0,
  Computer,
  BuiltinGroup,  // local security group with "domain" SID == S-1-5-32
  LocalGroup,
  DomainGroup,
  LocalUser,
  DomainUser,
  WellKnown      // SID_NAME_USE == SidTypeWellKnownGroup
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetLocalAccountPolicy]
public class NetLocalAccountPolicy
{
  public string ComputerName;
  public Boolean ForceLogoff;
  public uint? ForceLogoffMinutes;
  public Boolean PasswordsExpire;
  public uint? MaximumPasswordAgeDays;
  public uint MinimumPasswordAgeDays;
  public uint MinimumPasswordLength;
  public uint PasswordHistoryCount;
  public uint? LockoutDurationMinutes;
  public uint? LockoutObservationMinutes;
  public uint LockoutThresholdCount;

  public NetLocalAccountPolicy(string ComputerName,
    uint ForceLogoffSeconds,
    uint MaximumPasswordAgeSeconds,
    uint MinimumPasswordAgeSeconds,
    uint MinimumPasswordLength,
    uint PasswordHistoryCount,
    uint LockoutDurationSeconds,
    uint LockoutObservationSeconds,
    uint LockoutThresholdCount)
  {
    this.ComputerName = ComputerName.Length > 0 ?
      ComputerName :
      System.Environment.MachineName;
    this.ForceLogoff = ForceLogoffSeconds == TIMEQ_FOREVER ?
      false :
      true;
    this.ForceLogoffMinutes = ForceLogoffSeconds == TIMEQ_FOREVER ?
      (uint?)null :
      ForceLogoffSeconds / 60;
    this.PasswordsExpire = MaximumPasswordAgeSeconds == TIMEQ_FOREVER ?
      false :
      true;
    this.MaximumPasswordAgeDays = MaximumPasswordAgeSeconds == TIMEQ_FOREVER ?
      (uint?)null :
      MaximumPasswordAgeSeconds / 86400;
    this.MinimumPasswordAgeDays = MinimumPasswordAgeSeconds == 0 ?
      0 :
      MinimumPasswordAgeSeconds / 86400;
    this.MinimumPasswordLength = MinimumPasswordLength;
    this.PasswordHistoryCount = PasswordHistoryCount;
    this.LockoutDurationMinutes = LockoutThresholdCount > 0 ?
      (LockoutDurationSeconds > 0 ? LockoutDurationSeconds / 60 : 0) :
      (uint?)null;
    this.LockoutObservationMinutes = LockoutThresholdCount > 0 ?
      (LockoutObservationSeconds > 0 ? LockoutObservationSeconds / 60 : 0) :
      (uint?)null;
    this.LockoutThresholdCount = LockoutThresholdCount;
  }
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetPrincipal]
// Base class
public class NetPrincipal
{
  public string ComputerName;
  public string AuthorityName;
  public string Name;
  public System.Security.Principal.SecurityIdentifier SID;
  public NetPrincipalType? Type;

  // Base class must have constructor that uses zero arguments
  public NetPrincipal() {}

  // Name only: Assume current computer
  public NetPrincipal(string Name)
  {
    this.ComputerName = System.Environment.MachineName;
    this.AuthorityName = null;
    this.Name = Name;
    this.SID = null;
    this.Type = null;
  }

  // SID only
  public NetPrincipal(System.Security.Principal.SecurityIdentifier SID)
  {
    this.ComputerName = null;
    this.AuthorityName = null;
    this.Name = null;
    this.SID = SID;
    this.Type = null;
  }

  public NetPrincipal(string ComputerName,
    string AuthorityName,
    string Name,
    System.Security.Principal.SecurityIdentifier SID,
    SID_NAME_USE SIDType)
  {
    // If ComputerName empty, assume current computer
    this.ComputerName = ComputerName.Length > 0 ?
      ComputerName :
      System.Environment.MachineName;
    this.AuthorityName = AuthorityName;
    this.Name = Name;
    this.SID = SID;
    switch ( SIDType )
    {
      case SID_NAME_USE.SidTypeUser:
        // Local user if authority and computer names match; otherwise domain
        this.Type = this.AuthorityName.Equals(this.ComputerName, System.StringComparison.OrdinalIgnoreCase) ?
          NetPrincipalType.LocalUser :
          NetPrincipalType.DomainUser;
        break;
      case SID_NAME_USE.SidTypeGroup:
        this.Type = NetPrincipalType.DomainGroup;
        break;
      case SID_NAME_USE.SidTypeAlias:
        // Builtin group if domain part of sid is builtin; otherwise local
        this.Type = SID.IsEqualDomainSid(SECURITY_BUILTIN_DOMAIN_RID) ?
          NetPrincipalType.BuiltinGroup :
          NetPrincipalType.LocalGroup;
        break;
      case SID_NAME_USE.SidTypeWellKnownGroup:
        this.Type = NetPrincipalType.WellKnown;
        break;
      case SID_NAME_USE.SidTypeComputer:
        this.Type = NetPrincipalType.Computer;
        break;
      default:
        this.Type = NetPrincipalType.Unknown;
        break;
    }
  }

  public override string ToString()
  {
    return this.Name;
  }
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetLocalGroupPrincipal]
public class NetLocalGroupPrincipal : NetPrincipal
{
  public string Description;

  // Name only: Assume current computer
  public NetLocalGroupPrincipal(string Name)
  {
    this.ComputerName = System.Environment.MachineName;
    this.Name = Name;
  }

  public NetLocalGroupPrincipal(string ComputerName,
    string AuthorityName,
    string Name,
    System.Security.Principal.SecurityIdentifier SID,
    NetPrincipalType Type,
    string Description)
  {
    // If ComputerName parameter empty, assume current computer
    this.ComputerName = ComputerName.Length > 0 ?
      ComputerName :
      System.Environment.MachineName;
    this.AuthorityName = AuthorityName;
    this.Name = Name;
    this.SID = SID;
    this.Type = Type;
    this.Description = Description;
  }
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetLocalUserPrincipal]
public class NetLocalUserPrincipal : NetPrincipal
{
  public DateTime? AccountExpires;
  public string Description;
  public Boolean Enabled;
  public string FullName;
  public DateTime? LastLogon;
  public Boolean ChangePasswordAtLogon;
  public DateTime? PasswordLastSet;
  public DateTime? PasswordChangeable;
  public DateTime? PasswordExpires;
  public Boolean PasswordRequired;
  public Boolean UserMayChangePassword;
  public string ProfilePath;
  public string ScriptPath;
  public string HomeDrive;
  public string HomeDirectory;
  public uint UserAccountControl;

  // Name only: Assume current computer
  public NetLocalUserPrincipal(string Name)
  {
    this.ComputerName = System.Environment.MachineName;
    this.Name = Name;
  }

  public NetLocalUserPrincipal(string ComputerName,
    string AuthorityName,
    string Name,
    System.Security.Principal.SecurityIdentifier SID,
    NetPrincipalType Type,
    uint AccountExpires,
    string Description,
    Boolean Enabled,
    string FullName,
    uint LastLogon,
    Boolean ChangePasswordAtLogon,
    uint PasswordLastSet,
    uint PasswordChangeable,
    uint PasswordExpires,
    Boolean PasswordRequired,
    Boolean UserMayChangePassword,
    string ProfilePath,
    string ScriptPath,
    string HomeDrive,
    string HomeDirectory,
    uint UserAccountControl)
  {
    // If ComputerName empty, assume local computer
    this.ComputerName = ComputerName.Length > 0 ?
      ComputerName :
      System.Environment.MachineName;
    this.AuthorityName = AuthorityName;
    this.Name = Name;
    this.SID = SID;
    this.Type = Type;
    this.AccountExpires = DateTime.Now <= LatestDateTimeOffset.LocalDateTime ?
      (AccountExpires != TIMEQ_FOREVER ? DateTimeOffset.FromUnixTimeSeconds(AccountExpires).ToLocalTime().LocalDateTime : (DateTime?)null) :
      (DateTime?)null;
    this.Description = Description;
    this.Enabled = Enabled;
    this.FullName = FullName;
    this.LastLogon = DateTime.Now <= LatestDateTimeOffset.LocalDateTime ?
     (LastLogon != 0 ? DateTimeOffset.FromUnixTimeSeconds(LastLogon).ToLocalTime().LocalDateTime : (DateTime?)null) :
     (DateTime?)null;
    this.ChangePasswordAtLogon = ChangePasswordAtLogon;
    if ( PasswordLastSet > 0 ) {
      DateTime pwdLastSet = (DateTime.Now).AddSeconds(-PasswordLastSet);
      if ( pwdLastSet <= LatestDateTimeOffset.LocalDateTime ) {
        this.PasswordLastSet = pwdLastSet;
        DateTime pwdChangeable = pwdLastSet.AddSeconds(PasswordChangeable);
        this.PasswordChangeable = pwdChangeable <= LatestDateTimeOffset.LocalDateTime ? pwdChangeable : (DateTime?)null;
        if ( (UserAccountControl & UF_DONT_EXPIRE_PASSWD) == 0 ) {
          // UF_DONT_EXPIRE_PASSWD flag not set (password expires)
          if ( PasswordExpires != TIMEQ_FOREVER ) {
            DateTime pwdExpires = pwdLastSet.AddSeconds(PasswordExpires);
            this.PasswordExpires = pwdExpires <= LatestDateTimeOffset.LocalDateTime ? pwdExpires : (DateTime?)null;
          }
          else {
            // TIMEQ_FOREVER == password never expires
            this.PasswordExpires = (DateTime?)null;
          }
        }
        else {
          // UF_DONT_EXPIRE_PASSWD flag set (password never expires)
          this.PasswordExpires = (DateTime?)null;
        }
      }
      else {
        // Unsigned 32-bit integer time exceeded
        this.PasswordLastSet = (DateTime?)null;
        this.PasswordChangeable = (DateTime?)null;
        this.PasswordExpires = (DateTime?)null;
      }
    }
    else {
      // Password has never been set
      this.PasswordLastSet = (DateTime?)null;
      this.PasswordChangeable = (DateTime?)null;
      this.PasswordExpires = (DateTime?)null;
    }
    this.PasswordRequired = PasswordRequired;
    this.UserMayChangePassword = UserMayChangePassword;
    this.ProfilePath = ProfilePath;
    this.ScriptPath = ScriptPath;
    this.HomeDrive = HomeDrive;
    this.HomeDirectory = HomeDirectory;
    this.UserAccountControl = UserAccountControl;
  }
}

//=============================================================================
// advapi32.dll
//=============================================================================

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::LookupAccountName()
[DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool LookupAccountName(
  string lpSystemName,
  string lpAccountName,
  [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
  ref uint cbSid,
  System.Text.StringBuilder ReferencedDomainName,
  ref uint cchReferencedDomainName,
  out SID_NAME_USE peUse
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::LookupAccountSid()
[DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern bool LookupAccountSid(
  string lpSystemName,
  [MarshalAs(UnmanagedType.LPArray)] byte[] Sid,
  System.Text.StringBuilder Name,
  ref uint cchName,
  System.Text.StringBuilder ReferencedDomainName,
  ref uint cchReferencedDomainName,
  out SID_NAME_USE peUse
);


//=============================================================================
// netapi32.dll
//=============================================================================

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+DOMAIN_CONTROLLER_INFO]
// Used by DsGetDcName
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct DOMAIN_CONTROLLER_INFO {
  public string DomainControllerName;
  public string DomainControllerAddress;
  public uint DomainControllerAddressType;
  public Guid DomainGuid;
  public string DomainName;
  public string DnsForestName;
  public uint Flags;
  public string DcSiteName;
  public string ClientSiteName;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_0]
// Used by NetLocalGroupSetInfo to rename local security groups
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct LOCALGROUP_INFO_0 {
  public string lgrpi0_name;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_1]
// Used by NetLocalGroupAdd, NetLocalGroupEnum, and NetLocalGroupGetInfo
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct LOCALGROUP_INFO_1 {
  public string lgrpi1_name;
  public string lgrpi1_comment;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_1002]
// Used by NetLocalGroupSetInfo to set local security group descriptions
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct LOCALGROUP_INFO_1002 {
  public string lgrpi1002_comment;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_MEMBERS_INFO_0]
// Used by NetLocalGroupAddMembers, NetLocalGroupDelMembers, and NetLocalGroupGetMembers
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct LOCALGROUP_MEMBERS_INFO_0 {
  public IntPtr lgrmi0_sid;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NET_DISPLAY_USER]
// Used by NetQueryDisplayInformation to enumerate user accounts
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct NET_DISPLAY_USER {
  public string usri1_name;
  public string usri1_comment;
  public uint usri1_flags;
  public string usri1_full_name;
  public uint usri1_user_id;
  public uint usri1_next_index;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+SERVER_INFO_101]
// Used by NetServerGetInfo
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct SERVER_INFO_101 {
  public uint sv101_platform_id;
  public string sv101_name;
  public uint sv101_version_major;
  public uint sv101_version_minor;
  public uint sv101_type;
  public string sv101_comment;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_0]
// Used by NetUserSetInfo to rename user accounts
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_0 {
  public string usri0_name;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_4]
// Used by NetUserGetInfo and NetUserSetInfo
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_4 {
  public string usri4_name;
  public string usri4_password;
  public uint usri4_password_age;
  public uint usri4_priv;
  public string usri4_home_dir;
  public string usri4_comment;
  public uint usri4_flags;
  public string usri4_script_path;
  public uint usri4_auth_flags;
  public string usri4_full_name;
  public string usri4_usr_comment;
  public string usri4_parms;
  public string usri4_workstations;
  public uint usri4_last_logon;
  public uint usri4_last_logoff;
  public uint usri4_acct_expires;
  public uint usri4_max_storage;
  public uint usri4_units_per_week;
  public IntPtr usri4_logon_hours;
  public uint usri4_bad_pw_count;
  public uint usri4_num_logons;
  public string usri4_logon_server;
  public uint usri4_country_code;
  public uint usri4_code_page;
  public IntPtr usri4_user_sid;
  public uint usri4_primary_group_id;
  public string usri4_profile;
  public string usri4_home_dir_drive;
  public uint usri4_password_expired;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1003]
// Used by NetUserSetInfo to reset user account password
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1003 {
  public string usri1003_password;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1006]
// Used by NetUserSetInfo to set user account home directory
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1006 {
  public string usri1006_home_dir;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1007]
// Used by NetUserSetInfo to set user account description
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1007 {
  public string usri1007_comment;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1008]
// Used by NetUserSetInfo to update user account flags
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1008 {
  public uint usri1008_flags;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1009]
// Used by NetUserSetInfo to set user account logon script
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1009 {
  public string usri1009_script_path;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1011]
// Used by NetUserSetInfo to set user account full name
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1011 {
  public string usri1011_full_name;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1017]
// Used by NetUserSetInfo to set user account expiration
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1017 {
  public uint usri1017_acct_expires;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1052]
// Used by NetUserSetInfo to set user account profile path
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1052 {
  public string usri1052_profile;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1053]
// Used by NetUserSetInfo to set user account home drive
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_INFO_1053 {
  public string usri1053_home_dir_drive;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_0]
// Used by NetUserModalsGet to get password policy information
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_MODALS_INFO_0 {
  public uint usrmod0_min_passwd_len;
  public uint usrmod0_max_passwd_age;
  public uint usrmod0_min_passwd_age;
  public uint usrmod0_force_logoff;
  public uint usrmod0_password_hist_len;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_2]
// Used by NetUserModalsGet to get authority SID
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_MODALS_INFO_2 {
  public string usrmod2_domain_name;
  public IntPtr usrmod2_domain_id;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_3]
// Used by NetUserModalsGet to get account lockout information
[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct USER_MODALS_INFO_3 {
  public uint usrmod3_lockout_duration;
  public uint usrmod3_lockout_observation_window;
  public uint usrmod3_lockout_threshold;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1001]
// Used by NetUserModalsSet to set minimum password length
public struct USER_MODALS_INFO_1001 {
  public uint usrmod1001_min_passwd_len;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1002]
// Used by NetUserModalsSet to set maximum password age
public struct USER_MODALS_INFO_1002 {
  public uint usrmod1002_max_passwd_age;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1003]
// Used by NetUserModalsSet to set minimum password age
public struct USER_MODALS_INFO_1003 {
  public uint usrmod1003_min_passwd_age;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1004]
// Used by NetUserModalsSet to set forced logoff
public struct USER_MODALS_INFO_1004 {
  public uint usrmod1004_force_logoff;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1005]
// Used by NetUserModalsSet to set password history length
public struct USER_MODALS_INFO_1005 {
  public uint usrmod1005_password_hist_len;
}

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetApiBufferFree(IntPtr Buffer);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::DsGetDcName()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint DsGetDcName(
  string ComputerName,
  string DomainName,
  IntPtr DomainGuid,
  string SiteName,
  uint Flags,
  out IntPtr DomainControllerInfo
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupAdd()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupAdd(
  string servername,
  uint level,
  IntPtr buf,
  ref uint parm_err
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupAddMembers()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupAddMembers(
  string servername,
  string groupname,
  uint level,
  IntPtr buf,
  uint totalentries
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupDel()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupDel(
  string servername,
  string groupname
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupDelMembers()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupDelMembers(
  string servername,
  string groupname,
  uint level,
  IntPtr buf,
  uint totalentries
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupEnum()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupEnum(
  string servername,
  uint level,
  out IntPtr bufptr,
  uint prefmaxlen,
  out uint entriesread,
  out uint totalentries,
  ref uint resumehandle
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupGetInfo()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupGetInfo(
  string servername,
  string groupname,
  uint level,
  out IntPtr bufptr
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupGetMembers()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupGetMembers(
  string servername,
  string localgroupname,
  uint level,
  out IntPtr bufptr,
  uint prefmaxlen,
  out uint entriesread,
  out uint totalentries,
  ref uint resumehandle
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupSetInfo()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetLocalGroupSetInfo(
  string servername,
  string groupname,
  uint level,
  IntPtr buf,
  out uint parm_err
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetQueryDisplayInformation()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetQueryDisplayInformation(
  string ServerName,
  uint Level,
  uint Index,
  uint EntriesRequested,
  uint PreferredMaximumLength,
  ref uint ReturnedEntryCount,
  ref IntPtr SortedBuffer
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetServerGetInfo()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetServerGetInfo(
  string servername,
  uint level,
  ref IntPtr bufptr
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserAdd()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetUserAdd(
  string servername,
  uint level,
  IntPtr buf,
  ref uint parm_err
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserDel()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetUserDel(
  string servername,
  string username
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserGetInfo()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetUserGetInfo(
  string servername,
  string username,
  uint level,
  out IntPtr bufptr
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsGet()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetUserModalsGet(
  string servername,
  uint level,
  out IntPtr bufptr
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsSet()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetUserModalsSet(
  string servername,
  uint level,
  IntPtr buf,
  out uint parm_err
);

// [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserSetInfo()
[DllImport("netapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
public static extern uint NetUserSetInfo(
  string servername,
  string username,
  uint level,
  IntPtr buf,
  out uint parm_err
);
"@ -Namespace F5E1C3D31AC644ED981EAA159ADDD879 -Name NetAccounts


# Add type accelerators for objects
# =============================================================================
$TypeAccelerators = [PSObject].Assembly.GetType("System.Management.Automation.TypeAccelerators")
$TypeAccelerators::Add("NetLocalAccountPolicy","F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetLocalAccountPolicy")
$TypeAccelerators::Add("NetPrincipalType","F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetPrincipalType")
$TypeAccelerators::Add("NetPrincipal","F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetPrincipal")
$TypeAccelerators::Add("NetLocalGroupPrincipal","F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetLocalGroupPrincipal")
$TypeAccelerators::Add("NetLocalUserPrincipal","F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NetLocalUserPrincipal")


# General-use functions
# =============================================================================

# Writes a customized error to the error stream using either an error code (and
# associated details) or a [Management.Automation.ErrorRecord] object
function WriteCustomError {
  [CmdletBinding(DefaultParameterSetName = "ErrorCode")]
  param(
    [Parameter(ParameterSetName = "ErrorCode",Position = 0,Mandatory)]
    [Int]
    $errorCode,

    [Parameter(ParameterSetName = "ErrorRecord")]
    [Management.Automation.ErrorRecord]
    $errorRecord,

    [Parameter(ParameterSetName = "ErrorCode",Position = 1)]
    $subject,

    [Parameter(ParameterSetName = "ErrorCode")]
    [Management.Automation.ErrorCategory]
    $errorCategory = [Management.Automation.ErrorCategory]::NotSpecified,

    [Parameter(ParameterSetName = "ErrorCode")]
    $targetObject,

    [Int]
    $scope = 0,

    [Switch]
    $terminatingError
  )
  if ( $PSCmdlet.ParameterSetName -eq "ErrorCode" ) {
    $message = ([ComponentModel.Win32Exception] $errorCode).Message
    if ( $subject ) { $message += " - '$subject'" }
    $message += ((" (0x{0:X8})" -f $errorCode),(" ({0})" -f $errorCode))[$errorCode -ge 0]
    if ( (-not $PSBoundParameters.ContainsKey("errorCategory")) -and $ErrorCodeCategory.ContainsKey($errorCode) ) {
      $errorCategory = $ErrorCodeCategory[$errorCode]
    }
    $errorRecord = New-Object Management.Automation.ErrorRecord((New-Object ComponentModel.Win32Exception($errorCode,$message)),
      $message,$errorCategory,$targetObject)
  }
  $context = (Get-Variable "PSCmdlet" -Scope $scope).Value
  if ( -not $terminatingError ) {
    $context.WriteError($errorRecord)
  }
  else {
    $context.ThrowTerminatingError($errorRecord)
  }
}

# Input: Security.SecureString
# Output: String
function ConvertToString {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [Security.SecureString]
    $secStr
  )
  try {
    $strPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secStr)
    [Runtime.InteropServices.Marshal]::PtrToStringAuto($strPtr)
  }
  finally {
    if ( $strPtr -ne [IntPtr]::Zero ) {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($strPtr)
    }
  }
}

# Input: Security.Principal.SecurityIdentifier
# Output: IntPtr (must free after use)
# Allocates a SID in unmanaged memory and returns an IntPtr to it
# Note: Caller must use [Runtime.InteropServices.Marshal]::FreeHGlobal to
# free returned IntPtr
function NewSidPtr {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [Security.Principal.SecurityIdentifier]
    $sid
  )
  $sidBytes = New-Object Byte[] $sid.BinaryLength
  $sid.GetBinaryForm($sidBytes,0)
  $sidPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal($sid.BinaryLength)
  [Runtime.InteropServices.Marshal]::Copy($sidBytes,0,$sidPtr,$sid.BinaryLength)
  $sidPtr
}

# For a '\' delimited account name:
# If no '\' delimiters, returns the name unchanged
# If '\name' or 'name\', returns 'name'
# Otherwise, returns the last two parts of the name with '\' delimiter
function ResolveAccountName {
  [CmdletBinding()]
  param(
    [String]
    $accountName
  )
  $parts = $accountName.Split('\',[StringSplitOptions]::RemoveEmptyEntries)
  if ( $parts.Length -eq 1 ) {
    $parts[0]
  }
  else {
    "{0}\{1}" -f $parts[$parts.Length - 2],$parts[$parts.Length - 1]
  }
}

# For an account name 'authorityName\accountName', returns as a two element
# array (first element = authorityName, second element = accountName); if the
# account name doesn't have an authority name, the first element will be an
# empty string
function SplitAccountName {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $accountName
  )
  $parts = $accountName.Split('\',[StringSplitOptions]::RemoveEmptyEntries)
    if ( $parts.Length -eq 1 ) {
    "",$parts[0]
  }
  else {
    $parts[0],$parts[1]
  }
}

# Sets TEST_MODE variable in parent scope to $true if the
# PSMODULE_NETACCOUNTS_TESTMODE environment variable is set to 1, or $false
# othewise; we enable SupportsShouldProcess so we can bypass confirmation
# and WhatIf output if those preferences are set in the caller's scope
function SetTestMode {
  [CmdletBinding(SupportsShouldProcess)]
  param()
  Set-Variable TEST_MODE ($Env:PSMODULE_NETACCOUNTS_TESTMODE -eq 1) -Scope 1
}


# advapi32.dll interface functions
# =============================================================================

# API(s): LookupAccountName
# Input: Computer and account name
# Output: NetPrincipal
# -quiet = suppress writing errors to the error stream
function LookupAccountName {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $accountName,

    [Switch]
    $quiet
  )
  $sid = New-Object Byte[] 0
  $authorityName = New-Object Text.StringBuilder
  $sidLength = $authorityLength = 0
  $sidType = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+SID_NAME_USE]::SidTypeUnknown
  # First call gets buffer sizes; should return false and last Win32 error
  # code should be ERROR_INSUFFICIENT_BUFFER
  $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::LookupAccountName(
    $computerName,           # lpSystemName
    $accountName,            # lpAccountName
    $sid,                    # Sid
    [Ref] $sidLength,        # cbSid
    $authorityName,          # ReferencedDomainName
    [Ref] $authorityLength,  # cchReferencedDomainName
    [Ref] $sidType)          # peUse
  $lastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
  if ( (-not $result) -and ($lastError -eq $ERROR_INSUFFICIENT_BUFFER) ) {
    # Allocate and call again to retrieve data
    $sid = New-Object Byte[] $sidLength
    $authorityName = New-Object Text.StringBuilder($authorityLength)
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::LookupAccountName(
      $computerName,           # lpSystemName
      $accountName,            # lpAccountName
      $sid,                    # Sid
      [Ref] $sidLength,        # cbSid
      $authorityName,          # ReferencedDomainName
      [Ref] $authorityLength,  # cchReferencedDomainName
      [Ref] $sidType)          # peUse
    $lastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    if ( $result ) {
      New-Object NetPrincipal(
        $computerName,
        $authorityName.ToString(),
        $accountName.ToString(),
        (New-Object Security.Principal.SecurityIdentifier($sid,0)),
        $sidType
      )
    }
    else {
      if ( -not $quiet ) {
        $errorParams = @{
          errorCode = $lastError
          subject = ResolveAccountName "$computerName\$accountName"
          scope = 2
        }
        WriteCustomError @errorParams
      }
    }
  }
  else {
    if ( -not $quiet ) {
      $errorParams = @{
        errorCode = $lastError
        subject = ResolveAccountName "$computerName\$accountName"
        scope = 2
      }
      WriteCustomError @errorParams
    }
  }
}

# API(s): LookupAccountSid
# Input: Computer name and System.Security.Principal.SecurityIdentifier
# Output: NetPrincipal
# -quiet = suppress writing errors to the error stream
function LookupAccountSid {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [Security.Principal.SecurityIdentifier]
    $sid,

    [Switch]
    $quiet
  )
  $sidBytes = New-Object Byte[] $sid.BinaryLength
  $sid.GetBinaryForm($sidBytes,0)
  # LookupAccountSid might corrupt the heap in some circumstances; see:
  # https://stackoverflow.com/questions/58105981/
  # Workaround: Allocate sufficiently large buffers initially
  $accountName = New-Object Text.StringBuilder($MAX_OBJECT_NAME_LENGTH)
  $authorityName = New-Object Text.StringBuilder($MAX_OBJECT_NAME_LENGTH)
  $accountNameLength = $authorityNameLength = $MAX_OBJECT_NAME_LENGTH
  $sidType = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+SID_NAME_USE]::SidTypeUnknown
  $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::LookupAccountSid(
    $computerName,               # lpSystemName
    $sidBytes,                   # Sid
    $accountName,                # Name
    [Ref] $accountNameLength,    # cchName
    $authorityName,              # ReferencedDomainName
    [Ref] $authorityNameLength,  # cchReferencedDomainName
    [Ref] $sidType               # peUse
  )
  $lastError = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
  if ( $result ) {
    New-Object NetPrincipal(
      $computerName,
      $authorityName.ToString(),
      $accountName.ToString(),
      $sid,
      $sidType
    )
  }
  else {
    if ( -not $quiet ) {
      WriteCustomError $lastError ("$computerName\{0}" -f $sid.Value) -scope 2
    }
  }
}

# Input: NetPrincipal and optional computer name
# Output: NetPrincipal
# Used by Add-NetLocalGroupMember and Remove-NetLocalGroupMember -Member
# parameter that might contain partial information, such as containing only a
# SID or a name; this function attempts SID and name resolution using
# LookupAccountSid and LookupAccountName; if it succeeds, it outputs a new
# NetPrincipal object with complete information
function ResolvePrincipal {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [NetPrincipal]
    $principal,

    [Parameter(Position = 1)]
    [String]
    $computerName
  )
  # Use SID if principal has it
  if ( $null -ne $principal.SID ) {
    # Use computer name to attempt resolution if we have it
    if ( $computerName ) {
      $resolvedPrincipal = LookupAccountSid $computerName $principal.SID -quiet
      if ( $null -ne $resolvedPrincipal ) { return $resolvedPrincipal }
    }
    # Use ComputerName property of NetPrincipal object or local computer name if not set
    $computerName = ([Environment]::MachineName,$principal.ComputerName)[[Boolean] $principal.ComputerName]
    $resolvedPrincipal = LookupAccountSid $computerName $principal.SID -quiet
    if ( $null -ne $resolvedPrincipal ) { return $resolvedPrincipal }
    # All attempts to resolve the SID failed; write an error
    WriteCustomError $CO_E_NOMATCHINGNAMEFOUND $principal.SID.Value -scope 2
    return
  }
  # If specified, use computer name to attempt resolution
  if ( $computerName ) {
    $resolvedPrincipal = LookupAccountName $computerName $principal.Name -quiet
    if ( $null -ne $resolvedPrincipal ) { return $resolvedPrincipal }
  }
  # If name specified using '\', try resolving using name portion before '\'
  # as the computer name
  if ( $principal.Name.IndexOf("\") -ne -1 ) {
    $nameParts = SplitAccountName $principal.Name
    if ( -not $nameParts[0] ) {
      WriteCustomError $CO_E_NOMATCHINGSIDFOUND $principal.Name -scope 2
      return
    }
    $resolvedPrincipal = LookupAccountName $nameParts[0] $nameParts[1] -quiet
    if ( ($null -ne $resolvedPrincipal) -and ($nameParts[0] -eq $resolvedPrincipal.AuthorityName) ) {
      return $resolvedPrincipal
    }
    WriteCustomError $CO_E_NOMATCHINGSIDFOUND ("{0}\{1}" -f $nameParts[0],$nameParts[1]) -scope 2
    return
  }
  # If ComputerName property not empty, try resolving using it
  if ( $principal.ComputerName ) {
    $resolvedPrincipal = LookupAccountName $principal.ComputerName $principal.Name -quiet
    if ( $null -ne $resolvedPrincipal ) { return $resolvedPrincipal }
  }
  # If AuthorityName property not empty, try resolving using it
  if ( $principal.AuthorityName ) {
    $resolvedPrincipal = LookupAccountName $principal.AuthorityName $principal.Name -quiet
    if ( $null -ne $resolvedPrincipal ) { return $resolvedPrincipal }
  }
  # Finally, try resolving using local computer name and Name
  $resolvedPrincipal = LookupAccountName ([Environment]::MachineName) $principal.Name -quiet
  if ( $null -ne $resolvedPrincipal ) { return $resolvedPrincipal }
  # All attempts to resolve the name failed; write an error
  WriteCustomError $CO_E_NOMATCHINGSIDFOUND $principal.Name -scope 2
}


# netapi32.dll interface functions
# =============================================================================

# API(s): NetServerGetInfo
# Input: Computer name
# Output is UInt32:
# * ERROR_SUCCESS (0) if machine reachable and is not a DC
# * ERROR_NOT_SUPPORTED (0x32) if machine reachable and is a DC
# * Otherwise, error returned from NetServerGetInfo
# Writes error to error stream if NetServerGetInfo fails or if computer is DC;
# specify -terminatingError switch to throw statement-terminating error
function TestDC {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Switch]
    $terminatingError
  )
  $bufPtr = [IntPtr]::Zero
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetServerGetInfo(
      $computerName,  # servername
      101,            # level
      [Ref] $bufPtr   # bufptr
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $si = [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr,
        [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+SERVER_INFO_101])
      if ( (($si.sv101_type -band $SV_TYPE_DOMAIN_CTRL) -ne 0) -or (($si.sv101_type -band $SV_TYPE_DOMAIN_BAKCTRL) -ne 0) ) {
        $result = $ERROR_NOT_SUPPORTED
      }
    }
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
  if ( $result -ne $ERROR_SUCCESS ) {
    WriteCustomError $result $computerName -scope 2 -terminatingError:$terminatingError
  }
  return $result
}

# API(s): DsGetDcName
# Input: Domain name
# Output: Server name of domain controller in specified domain
function DsGetDCName {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $domainName
  )
  $dcInfoPtr = [IntPtr]::Zero
  $flags = $DS_DIRECTORY_SERVICE_REQUIRED -bor $DS_IP_REQUIRED
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::DsGetDcName(
      "",                   # ComputerName
      $domainName,          # DomainName
      [IntPtr]::Zero,       # DomainGuid
      "",                   # SiteName
      $flags,               # Flags
      [Ref] $dcInfoPtr      # DomainControllerInfo
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $dcInfo = [Runtime.InteropServices.Marshal]::PtrToStructure($dcInfoPtr,
        [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+DOMAIN_CONTROLLER_INFO])
      # Output the DC name without leading '\\'
      $dcInfo.DomainControllerName -replace '^\\\\',''
    }
    else {
      WriteCustomError $result $domainName -scope 3
    }
  }
  finally {
    if ( $dcInfoPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($dcInfoPtr)
    }
  }
}

# API(s): NetLocalGroupAdd
# Module function(s): New-NetLocalGroup
# Input: Computer name, group name, description
# Output: Zero for success, non-zero for failure
function NetLocalGroupAdd {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $groupName,

    [Parameter(Position = 2)]
    [String]
    $description
  )
  $lgi = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_1
  $lgi.lgrpi1_name = $groupName
  if ( $description ) {
    $lgi.lgrpi1_comment = $description
  }
  $parmErr = 0
  try {
    $bufPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($lgi))
    [Runtime.InteropServices.Marshal]::StructureToPtr($lgi,$bufPtr,$false)
    if ( -not $TEST_MODE ) {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupAdd(
        $computerName,  # servername
        1,              # level
        $bufPtr,        # buf
        [Ref] $parmErr  # parm_err
      )
    }
    else {
      $result = $ERROR_SUCCESS
      $testMessage = 'TEST: NetLocalGroupAdd {0}{1}' -f $computerName,[Environment]::NewLine
      $testMessage += '      LOCALGROUP_INFO_1.lgrpi1_name = {0}{1}' -f $lgi.lgrpi1_name,[Environment]::NewLine
      $testMessage += '      LOCALGROUP_INFO_1.lgrpi1_comment = {0}' -f $lgi.lgrpi1_comment
      Write-Host $testMessage -ForegroundColor $TEST_COLOR
    }
    if ( $result -ne $ERROR_SUCCESS ) {
      WriteCustomError $result (ResolveAccountName "$computerName\$groupName") -scope 2
    }
  }
  finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($bufPtr)
  }
  $result
}

# API(s): LookupAccountSid, NetLocalGroupAddMembers, NetLocalGroupDelMembers
# Module function(s): Add-NetLocalGroupMember and Remove-NetLocalGroupMember
# Input: Action ("Add" or "Remove"), computer name, local security group name,
# and SID of member to add or remove
function NetLocalGroupChangeMembers {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [ValidateSet("Add","Remove")]
    $action,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 2,Mandatory)]
    [String]
    $groupName,

    [Parameter(Position = 3,Mandatory)]
    [Security.Principal.SecurityIdentifier]
    $sid
  )
  $method = ("NetLocalGroupDelMembers","NetLocalGroupAddMembers")[$action -eq "Add"]
  $memberPrincipal = LookupAccountSid $computerName $sid
  if ( $null -ne $memberPrincipal ) {
    $lgmi = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_MEMBERS_INFO_0
    try {
      $sidPtr = NewSidPtr $sid
      $lgmi.lgrmi0_sid = $sidPtr
      try {
        $bufPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($lgmi))
        [Runtime.InteropServices.Marshal]::StructureToPtr($lgmi,$bufPtr,$false)
        if ( -not $TEST_MODE ) {
          $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::$method(
            $computerName,  # servername
            $groupName,     # groupname
            0,              # level
            $bufPtr,        # buf
            1               # totalentries
          )
        }
        else {
          $result = $ERROR_SUCCESS
          $testMessage = 'TEST: {0} {1} "{2}"{3}' -f $method,$computerName,$groupName,[Environment]::NewLine
          $testMessage += '      LOCALGROUP_MEMBERS_INFO_0.lgrmi0_sid = {0} [{1}\{2}]' -f $sid.Value,
            $memberPrincipal.AuthorityName,$memberPrincipal.Name
          Write-Host $testMessage -ForegroundColor $TEST_COLOR
        }
        if ( $result -ne $ERROR_SUCCESS ) {
          $errorParams = @{
            errorCode = $result
            subject = ResolveAccountName ("{0}\{1}" -f $memberPrincipal.AuthorityName,$memberPrincipal.Name)
            scope = 2
          }
          WriteCustomError @errorParams
        }
      }
      finally {
        if ( $bufPtr -ne [IntPtr]::Zero ) {
          [Runtime.InteropServices.Marshal]::FreeHGlobal($bufPtr)
        }
      }
    }
    finally {
      if ( $sidPtr -ne [IntPtr]::Zero ) {
        [Runtime.InteropServices.Marshal]::FreeHGlobal($sidPtr)
      }
    }
  }
}

# API(s): NetLocalGroupDel
# Module function(s): Remove-NetLocalGroup
# Input: Computer name and group name
function NetLocalGroupDel {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $groupName
  )
  if ( -not $TEST_MODE ) {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupDel(
      $computerName,  # servername
      $groupName      # groupname
    )
  }
  else {
    $result = $ERROR_SUCCESS
    Write-Host ('TEST: NetLocalGroupDel {0} "{1}"' -f $computerName,$groupName) -ForegroundColor $TEST_COLOR
  }
  if ( $result -ne $ERROR_SUCCESS ) {
    WriteCustomError $result (ResolveAccountName "$computerName\$groupName") -scope 2
  }
}

# API(s): NetLocalGroupEnum, LookupAccountName
# Module function(s): Get-NetLocalGroup without a name qualifier
# Input: Computer name
# Output: NetLocalGroupPrincipal[]
function NetLocalGroupEnum {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName
  )
  $bufPtr = [IntPtr]::Zero
  $entriesRead = $totalEntries = $resumeHandle = 0
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupEnum(
      $computerName,          # servername
      1,                      # level
      [Ref] $bufPtr,          # bufptr
      $MAX_PREFERRED_LENGTH,  # prefmaxlen
      [Ref] $entriesRead,     # entriesread
      [Ref] $totalEntries,    # totalentries
      [Ref] $resumeHandle     # resumehandle
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $bufOffset = $bufPtr.ToInt64()
      for ( ; $entriesRead -gt 0; $entriesRead-- ) {
        $entryPtr = [IntPtr] $bufOffset
        $outStruct = [Runtime.InteropServices.Marshal]::PtrToStructure($entryPtr,
          [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_1])
        $principal = LookupAccountName $computerName $outStruct.lgrpi1_name
        if ( $null -ne $principal ) {
          New-Object NetLocalGroupPrincipal(
            $principal.ComputerName,
            $principal.AuthorityName,
            $principal.Name,
            $principal.SID,
            $principal.Type,
            $outStruct.lgrpi1_comment  # Description
          )
        }
        $bufOffset += [Runtime.InteropServices.Marshal]::SizeOf($outStruct)
      }
    }
    else {
      WriteCustomError $result $computerName -scope 2
    }
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
}

# API(s): NetLocalGroupGetMembers, LookupAccountSid
# Module function(s): Get-NetLocalGroupMember
# Input: Computer and group name
# Output: NetPrincipal[]
function NetLocalGroupGetMembers {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $groupName
  )
  $bufPtr = [IntPtr]::Zero
  $entriesRead = $totalEntries = $resumeHandle = 0
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupGetMembers(
      $computerName,          # servername
      $groupName,             # localgroupname
      0,                      # level
      [Ref] $bufPtr,          # bufptr
      $MAX_PREFERRED_LENGTH,  # prefmaxlen
      [Ref] $entriesRead,     # entriesread
      [Ref] $totalEntries,    # totalentries
      [Ref] $resumeHandle     # resumehandle
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $bufOffset = $bufPtr.ToInt64()
      for ( ; $entriesRead -gt 0; $entriesRead-- ) {
        $entryPtr = [IntPtr] $bufOffset
        $outStruct = [Runtime.InteropServices.Marshal]::PtrToStructure($entryPtr,
          [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_MEMBERS_INFO_0])
        LookupAccountSid $computerName (New-Object Security.Principal.SecurityIdentifier($outStruct.lgrmi0_sid))
        $bufOffset += [Runtime.InteropServices.Marshal]::SizeOf($outStruct)
      }
    }
    else {
      WriteCustomError $result (ResolveAccountName "$computerName\$groupName") -scope 2
    }
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
}

# API(s): NetLocalGroupGetInfo, LookupAccountName
# Module function(s): Get-NetLocalGroup with a name qualifier
# Input: Computer and group name
# Output: NetLocalGroupPrincipal
function NetLocalGroupGetInfo {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $groupName
  )
  $bufPtr = [IntPtr]::Zero
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupGetInfo(
      $computerName,  # servername
      $groupName,     # groupname
      1,              # level
      [Ref] $bufPtr   # bufptr
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $outStruct = [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr,
        [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_1])
      $principal = LookupAccountName $computerName $outStruct.lgrpi1_name
      if ( $null -ne $principal ) {
        New-Object NetLocalGroupPrincipal(
          $principal.ComputerName,
          $principal.AuthorityName,
          $principal.Name,
          $principal.SID,
          $principal.Type,
          $outStruct.lgrpi1_comment  # Description
        )
      }
    }
    else {
      WriteCustomError $result (ResolveAccountName "$computerName\$groupName") -scope 2
    }
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
}

# API(s): NetLocalGroupSetInfo
# Module function(s): Set-NetLocalGroup
# Input: Computer name, group name, and new group name or description
function NetLocalGroupSetInfo {
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = "Description",Position = 0,Mandatory)]
    [Parameter(ParameterSetName = "Rename",Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(ParameterSetName = "Description",Position = 1,Mandatory)]
    [Parameter(ParameterSetName = "Rename",Position = 1,Mandatory)]
    [String]
    $groupName,

    [Parameter(ParameterSetName = "Description",Mandatory)]
    [String]
    $description,

    [Parameter(ParameterSetName = "Rename",Mandatory)]
    [String]
    $newName
  )
  switch ( $PSCmdlet.ParameterSetName ) {
    "Description" {
      $level = 1002
      $lgi = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_1002
      $lgi.lgrpi1002_comment = $description
    }
    "Rename" {
      $level = 0
      $lgi = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+LOCALGROUP_INFO_0
      $lgi.lgrpi0_name = $newName
    }
  }
  $parmErr = 0
  try {
    $bufPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($lgi))
    [Runtime.InteropServices.Marshal]::StructureToPtr($lgi,$bufPtr,$false)
    if ( -not $TEST_MODE ) {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetLocalGroupSetInfo(
        $computerName,  # servername
        $groupName,     # groupname
        $level,         # level
        $bufPtr,        # buf
        [Ref] $parmErr  # parm_err
      )
    }
    else {
      $result = $ERROR_SUCCESS
      $testMessage = 'TEST: NetLocalGroupSetInfo {0} "{1}"{2}' -f $computerName,$groupName,[Environment]::NewLine
      switch ( $PSCmdlet.ParameterSetName ) {
        "Description" { $testMessage += '      LOCALGROUP_INFO_0.lgrpi1002_comment = {0}' -f $lgi.lgrpi1002_comment }
        "Rename"      { $testMessage += '      LOCALGROUP_INFO_0.lgrpi0_name = {0}' -f $lgi.lgrpi0_name }
      }
      Write-Host $testMessage -ForegroundColor $TEST_COLOR
    }
    if ( $result -ne $ERROR_SUCCESS ) {
      WriteCustomError $result (ResolveAccountName "$computerName\$groupName") -scope 2
    }
  }
  finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($bufPtr)
  }
  # Returns exit code to be like NetUserSetInfo; callers can usually ignore
  $result
}

# API(s): NetUserModalsGet
# Module function(s): Get-NetLocalAccountPolicy
# Input: Computer name and error scope
# Output: If -level specified, output is API struct; otherwise, output is
# NetLocalAccountPolicy object
# (Note: Don't extend this function to return information level 2 because the
# SID pointer won't be valid after the function returns)
function NetUserModalsGet {
  [CmdletBinding(DefaultParameterSetName = "AccountInfoOutput")]
  param(
    [Parameter(ParameterSetName = "AccountInfoOutput",Position = 0,Mandatory)]
    [Parameter(ParameterSetName = "ApiOutput",Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(ParameterSetName = "ApiOutput",Mandatory)]
    [ValidateSet(0,3)]
    [Int]
    $level,

    [Parameter(ParameterSetName = "AccountInfoOutput")]
    [Parameter(ParameterSetName = "ApiOutput")]
    [Int]
    $errorScope = 0
  )
  if ( $PSCmdlet.ParameterSetName -eq "ApiOutput" ) {
    $bufPtr = [IntPtr]::Zero
    $structType = "F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_{0}" -f $level
    try {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsGet(
        $computerName,  # servername
        $level,         # level
        [Ref] $bufPtr   # bufptr
      )
      if ( $result -eq $ERROR_SUCCESS ) {
        [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr,[Type] $structType)
      }
      else {
        WriteCustomError $result $computerName -scope $errorScope
      }
    }
    finally {
      if ( $bufPtr -ne [IntPtr]::Zero ) {
        [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
      }
    }
  }
  else {
    $bufPtr0 = $bufPtr3 = [IntPtr]::Zero
    try {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsGet(
        $computerName,  # servername
        0,              # level
        [Ref] $bufPtr0  # bufptr
      )
      if ( $result -eq $ERROR_SUCCESS ) {
        $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsGet(
          $computerName,  # servername
          3,              # level
          [Ref] $bufPtr3  # bufptr
        )
      }
      if ( $result -eq $ERROR_SUCCESS ) {
        $outStruct0 = [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr0,
          [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_0])
        $outStruct3 = [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr3,
          [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_3])
        New-Object NetLocalAccountPolicy(
          $computerName,                                   # computerName
          $outStruct0.usrmod0_force_logoff,                # ForceLogoffSeconds
          $outStruct0.usrmod0_max_passwd_age,              # MaximumPasswordAgeSeconds
          $outStruct0.usrmod0_min_passwd_age,              # MinimumPasswordAgeSeconds
          $outStruct0.usrmod0_min_passwd_len,              # MinimumPasswordLength
          $outStruct0.usrmod0_password_hist_len,           # PasswordHistoryCount
          $outStruct3.usrmod3_lockout_duration,            # LockoutDurationSeconds
          $outStruct3.usrmod3_lockout_observation_window,  # LockoutObservationSeconds
          $outStruct3.usrmod3_lockout_threshold            # LockoutThresholdCount
        )
      }
      else {
        WriteCustomError $result $computerName -scope $errorScope
      }
    }
    finally {
      if ( $bufPtr0 -ne [IntPtr]::Zero ) {
        [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr0)
      }
      if ( $bufPtr3 -ne [IntPtr]::Zero ) {
        [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr3)
      }
    }
  }
}

# API(s): NetUserModalsGet
# Input: Computer name
# Output: Security.Principal.SecurityIdentifier of account authority SID for
# the specified computer name (if computer is a domain controller, this is the
# account authority SID of the DC's domain)
function GetAuthoritySID {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Int]
    $errorScope = 0
  )
  # Call NetUserModalsGet API directly in order to access SID pointer while
  # still valid (before freeing buffer)
  $bufPtr = [IntPtr]::Zero
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsGet(
      $computerName,  # servername
      2,              # level
      [Ref] $bufPtr   # bufptr
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $um = [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr,
        [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_2])
      New-Object Security.Principal.SecurityIdentifier($um.usrmod2_domain_id)
    }
    else {
      WriteCustomError $result $computerName -scope $errorScope
    }
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
}

# Input: Computer name
# Module function(s): Get-NetLocalAdminUser
# Output: Security.Principal.SecurityIdentifier of local Administrator user
# account on that computer
function GetLocalAdminSID {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName
  )
  $computerSID = GetAuthoritySID $computerName -errorScope 3
  if ( $null -ne $computerSID ) {
    New-Object Security.Principal.SecurityIdentifier([Security.Principal.WellKnownSidType]::AccountAdministratorSid,
      $computerSID)
  }
}

# Input: Domain name
# Module function(s): Get-WellknownNetPrincipal
# Output: Security.Principal.SecurityIdentifier of Domain Admins group for
# that domain
function GetDomainAdminsSID {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $domainName
  )
  $dcName = DsGetDcName $domainName
  if ( $null -ne $dcName ) {
    $domainSID = GetAuthoritySID $dcName -errorScope 3
    if ( $null -ne $domainSID ) {
      New-Object Security.Principal.SecurityIdentifier([Security.Principal.WellKnownSidType]::AccountDomainAdminsSid,
        $domainSID)
    }
  }
}

# API(s): NetUserGetInfo
# Module function(s): Get-NetLocalUser with a name qualifier
# If caller specifies -level, the function outputs the struct; otherwise the
# output is a NetLocalUserPrincipal object
function NetUserGetInfo {
  [CmdletBinding(DefaultParameterSetName = "PrincipalOutput")]
  param(
    [Parameter(ParameterSetName = "PrincipalOutput",Position = 0,Mandatory)]
    [Parameter(ParameterSetName = "ApiOutput",Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(ParameterSetName = "PrincipalOutput",Position = 1,Mandatory)]
    [Parameter(ParameterSetName = "ApiOutput",Position = 1,Mandatory)]
    $userName,

    [Parameter(ParameterSetName = "PrincipalOutput",Position = 2,Mandatory)]
    [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_0]
    $pwInfo,

    [Parameter(ParameterSetName = "ApiOutput",Position = 2,Mandatory)]
    [ValidateSet(4)]
    [Int]
    $level
  )
  if ( $PSCmdlet.ParameterSetName -eq "PrincipalOutput" ) { $level = 4 }
  $bufPtr = [IntPtr]::Zero
  try {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserGetInfo(
      $computerName,  # servername
      $userName,      # username
      $level,         # level
      [Ref] $bufPtr   # bufptr
    )
    if ( $result -eq $ERROR_SUCCESS ) {
      $structType = "F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_{0}" -f $level
      $outStruct = [Runtime.InteropServices.Marshal]::PtrToStructure($bufPtr,[Type] $structType)
      if ( $PSCmdlet.ParameterSetName -eq "PrincipalOutput" ) {
        $principal = LookupAccountSid $computerName (New-Object Security.Principal.SecurityIdentifier($outStruct.usri4_user_sid))
        if ( $null -ne $principal ) {
          New-Object NetLocalUserPrincipal(
            $principal.ComputerName,
            $principal.AuthorityName,
            $principal.Name,
            $principal.SID,
            $principal.Type,
            $outstruct.usri4_acct_expires,                                  # AccountExpires
            $outStruct.usri4_comment,                                       # Description
            (($outStruct.usri4_flags -band $UF_ACCOUNTDISABLE) -eq 0),      # Enabled
            $outStruct.usri4_full_name,                                     # FullName
            $outStruct.usri4_last_logon,                                    # LastLogon
            ($outStruct.usri4_password_expired -ne 0),                      # ChangePasswordAtLogon
            $outStruct.usri4_password_age,                                  # PasswordLastSet
            $pwInfo.usrmod0_min_passwd_age,                                 # PasswordChangeable
            $pwInfo.usrmod0_max_passwd_age,                                 # PasswordExpires
            (($outStruct.usri4_flags -band $UF_PASSWD_NOTREQD) -eq 0),      # PasswordRequired
            (($outStruct.usri4_flags -band $UF_PASSWD_CANT_CHANGE) -eq 0),  # UserMayChangePassword
            $outStruct.usri4_profile,                                       # ProfilePath
            $outStruct.usri4_script_path,                                   # ScriptPath
            $outStruct.usri4_home_dir_drive,                                # HomeDrive
            $outStruct.usri4_home_dir,                                      # HomeDirectory
            $outstruct.usri4_flags                                          # UserAccountControl
          )
        }
      }
      else {
        $outStruct
        if ( $TEST_MODE ) {
          $testMessage = 'TEST: NetUserGetInfo {0} "{1}"{2}' -f $computerName,$userName,[Environment]::NewLine
          $testMessage += '      USER_INFO_4.usri4_flags = 0x{0:X8}{1}' -f $outStruct.usri4_flags,[Environment]::NewLine
          $testMessage += '      USER_INFO_4.usri4_password_expired = 0x{0:X8}' -f $outStruct.usri4_password_expired
          Write-Host $testMessage -ForegroundColor $TEST_COLOR
        }
      }
    }
    else {
      WriteCustomError $result (ResolveAccountName "$computerName\$userName") -scope 2
    }
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
}

# API(s): NetQueryDisplayInformation, NetUserGetInfo
# Module function(s): Get-NetLocalUser without a name qualifier
# Input: Computer name and USER_MODALS_INFO_0
# Output: NetLocalUserPrincipal[]
function NetQueryDisplayInformation {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_0]
    $pwInfo
  )
  $index = $returnedEntryCount = 0
  $bufPtr = [IntPtr]::Zero
  try {
    do {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetQueryDisplayInformation(
        $computerName,              # ServerName
        1,                          # Level
        $index,                     # Index
        100,                        # EntriesRequested
        $MAX_PREFERRED_LENGTH,      # PreferredMaximumLength
        [Ref] $returnedEntryCount,  # ReturnedEntryCount
        [Ref] $bufPtr)              # SortedBuffer
      if ( ($result -eq $ERROR_MORE_DATA) -or ($result -eq $ERROR_SUCCESS) ) {
        $entryOffset = $bufPtr.ToInt64()
        for ( ; $returnedEntryCount -gt 0; $returnedEntryCount-- ) {
          $entryPtr = [IntPtr] $entryOffset
          $outStruct = [Runtime.InteropServices.Marshal]::PtrToStructure($entryPtr,
            [Type] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+NET_DISPLAY_USER])
          if ( ($outStruct.usri1_flags -band $UF_NORMAL_ACCOUNT) -ne 0 ) {
            NetUserGetInfo $computerName $outStruct.usri1_name $pwInfo
          }
          $index = $outStruct.usri1_next_index
          $entryOffset += [Runtime.InteropServices.Marshal]::SizeOf($outStruct)
        }
      }
      else {
        WriteCustomError $result $computerName -scope 2
      }
    }
    while ( $result -eq $ERROR_MORE_DATA )
  }
  finally {
    if ( $bufPtr -ne [IntPtr]::Zero ) {
      [Void] [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetApiBufferFree($bufPtr)
    }
  }
}

# API: NetUserAdd
# Module function(s): New-NetLocalUser
# Input: Computer name, user name, and other properties
# Output: Zero for success, non-zero for failure
function NetUserAdd {
  [CmdletBinding(DefaultParameterSetName = "Password")]
  param(
    [Parameter(ParameterSetName = "Password",Position = 0,Mandatory)]
    [Parameter(ParameterSetName = "NoPassword",Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(ParameterSetName = "Password",Position = 0,Mandatory)]
    [Parameter(ParameterSetName = "NoPassword",Position = 0,Mandatory)]
    [Parameter(Position = 1,Mandatory)]
    [String]
    $userName,

    [DateTime]
    $accountExpires,

    [String]
    $description,

    [Switch]
    $disabled,

    [String]
    $fullName,

    [Parameter(ParameterSetName = "NoPassword",Mandatory)]
    [Switch]
    $noPassword,

    [Parameter(ParameterSetName = "Password",Mandatory)]
    [Security.SecureString]
    $password,

    [Switch]
    $changePasswordAtLogon,

    [Switch]
    $passwordNeverExpires,

    [Switch]
    $passwordRequired,

    [Switch]
    $userMayNotChangePassword,

    [String]
    $profilePath,

    [String]
    $scriptPath,

    [String]
    $homeDrive,

    [String]
    $homeDirectory
  )
  $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_4
  $ui.usri4_name = $userName
  if ( $password ) { $ui.usri4_password = ConvertToString $password }
  if ( $description ) { $ui.usri4_comment = $description }
  if ( $homeDirectory ) { $ui.usri4_home_dir = $homeDirectory }
  $ui.usri4_flags = $UF_SCRIPT  # Per MSDN, required for new accounts
  if ( $disabled ) { $ui.usri4_flags = $ui.usri4_flags -bor $UF_ACCOUNTDISABLE }
  if ( $passwordNeverExpires ) { $ui.usri4_flags = $ui.usri4_flags -bor $UF_DONT_EXPIRE_PASSWD }
  if ( -not $passwordRequired ) { $ui.usri4_flags = $ui.usri4_flags -bor $UF_PASSWD_NOTREQD }
  if ( $userMayNotChangePassword ) { $ui.usri4_flags = $ui.usri4_flags -bor $UF_PASSWD_CANT_CHANGE }
  if ( $scriptPath ) { $ui.usri4_script_path = $scriptPath }
  if ( $fullName ) { $ui.usri4_full_name = $fullName }
  if ( $PSBoundParameters.ContainsKey("accountExpires") ) {
    $accountExpirationSeconds = ([DateTimeOffset] $accountExpires.ToUniversalTime()).ToUnixTimeSeconds()
    if ( $accountExpirationSeconds -ge [UInt32]::MaxValue ) {
      $accountExpirationSeconds = $TIMEQ_FOREVER
    }
    $ui.usri4_acct_expires = $accountExpirationSeconds
  }
  else {
    $ui.usri4_acct_expires = $TIMEQ_FOREVER
  }
  # Per MSDN, the following are required for new accounts:
  # * usri4_max_storage = USER_MAXSTORAGE_UNLIMITED
  # * usri4_primary_group_id = DOMAIN_GROUP_RID_USERS
  $ui.usri4_max_storage = $USER_MAXSTORAGE_UNLIMITED
  $ui.usri4_primary_group_id = $DOMAIN_GROUP_RID_USERS
  if ( $profilePath ) { $ui.usri4_profile = $profilePath }
  if ( $homeDrive ) { $ui.usri4_home_dir_drive = $homeDrive }
  $ui.usri4_password_expired = (0,1)[$changePasswordAtLogon.IsPresent]
  $parmErr = 0
  try {
    $bufPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($ui))
    [Runtime.InteropServices.Marshal]::StructureToPtr($ui,$bufPtr,$false)
    if ( -not $TEST_MODE ) {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserAdd(
        $computerName,  # servername
        4,              # level
        $bufPtr,        # buf
        [Ref] $parmErr  # parm_err
      )
    }
    else {
      $result = $ERROR_SUCCESS
      $testMessage = 'TEST: NetUserAdd {0}{1}' -f $computerName,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_name = {0}{1}' -f $ui.usri4_name,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_password = {0}{1}' -f $ui.usri4_password,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_home_dir = {0}{1}' -f $ui.usri4_home_dir,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_comment = {0}{1}' -f $ui.usri4_comment,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_flags = 0x{0:X8}{1}' -f $ui.usri4_flags,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_script_path = {0}{1}' -f $ui.usri4_script_path,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_full_name = {0}{1}' -f $ui.usri4_full_name,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_acct_expires = 0x{0:X8}{1}' -f $ui.usri4_acct_expires,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_max_storage = 0x{0:X8}{1}' -f $ui.usri4_max_storage,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_primary_group_id = 0x{0:X8}{1}' -f $ui.usri4_primary_group_id,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_profile = {0}{1}' -f $ui.usri4_profile,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_home_dir_drive = {0}{1}' -f $ui.usri4_home_dir_drive,[Environment]::NewLine
      $testMessage += '      USER_INFO_4.usri4_password_expired = 0x{0:X8}' -f $ui.usri4_password_expired
      Write-Host $testMessage -ForegroundColor $TEST_COLOR
    }
    if ( $result -ne $ERROR_SUCCESS ) {
      WriteCustomError $result (ResolveAccountName "$computerName\$userName") -scope 2
    }
  }
  finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($bufPtr)
  }
  $result
}

# API: NetUserDel
# Module function(s): Remove-NetLocalUser
# Input: Computer name and user name
# Output: Zero for success, non-zero for failure
function NetUserDel {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $userName
  )
  if ( -not $TEST_MODE ) {
    $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserDel(
      $computerName,  # servername
      $userName       # username
    )
  }
  else {
    $result = $ERROR_SUCCESS
    Write-Host ('TEST: NetUserDel {0} "{1}"' -f $computerName,$userName) -ForegroundColor $TEST_COLOR
  }
  if ( $result -ne $ERROR_SUCCESS ) {
    WriteCustomError $result (ResolveAccountName "$computerName\$userName")-scope 2
  }
}

# API: NetUserModalsSet
# Module function(s): Set-NetLocalAccountPolicy
# Input: Computer name and other properties
# Output: Zero for success, non-zero for failure
function NetUserModalsSet {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(ParameterSetName = "AccountLockout",Mandatory)]
    [UInt32]
    $lockoutDurationSeconds,

    [Parameter(ParameterSetName = "AccountLockout",Mandatory)]
    [Int]
    $lockoutObservationSeconds,

    [Parameter(ParameterSetName = "AccountLockout",Mandatory)]
    [UInt32]
    $lockoutThresholdCount,

    [Parameter(ParameterSetName = "MinimumPasswordLength",Mandatory)]
    [UInt32]
    $minimumPasswordLength,

    [Parameter(ParameterSetName = "MaximumPasswordAge",Mandatory)]
    [UInt32]
    $maximumPasswordAgeSeconds,

    [Parameter(ParameterSetName = "MinimumPasswordAge",Mandatory)]
    [UInt32]
    $minimumPasswordAgeSeconds,

    [Parameter(ParameterSetName = "ForceLogoff",Mandatory)]
    [UInt32]
    $forceLogoffSeconds,

    [Parameter(ParameterSetName = "PasswordHistoryCount",Mandatory)]
    [UInt32]
    $passwordHistoryCount
  )
  switch ($PSCmdlet.ParameterSetName ) {
    "AccountLockout" {
      $level = 3
      $um = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_3
      $um.usrmod3_lockout_duration = $lockoutDurationSeconds
      $um.usrmod3_lockout_observation_window = $lockoutObservationSeconds
      $um.usrmod3_lockout_threshold = $lockoutThresholdCount
    }
    "MinimumPasswordLength" {
      $level = 1001
      $um = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1001
      $um.usrmod1001_min_passwd_len = $minimumPasswordLength
    }
    "MaximumPasswordAge" {
      $level = 1002
      $um = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1002
      $um.usrmod1002_max_passwd_age = $maximumPasswordAgeSeconds
    }
    "MinimumPasswordAge" {
      $level = 1003
      $um = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1003
      $um.usrmod1003_min_passwd_age = $minimumPasswordAgeSeconds
    }
    "ForceLogoff" {
      $level = 1004
      $um = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1004
      $um.usrmod1004_force_logoff = $forceLogoffSeconds
    }
    "PasswordHistoryCount" {
      $level = 1005
      $um = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_MODALS_INFO_1005
      $um.usrmod1005_password_hist_len = $passwordHistoryCount
    }
  }
  $parmErr = 0
  try {
    $bufPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($um))
    [Runtime.InteropServices.Marshal]::StructureToPtr($um,$bufPtr,$false)
    if ( -not $TEST_MODE ) {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserModalsSet(
        $computerName,  # servername
        $level,         # level
        $bufPtr,        # buf
        [Ref] $parmErr  # parm_err
      )
    }
    else {
      $result = $ERROR_SUCCESS
      $testMessage = 'TEST: NetUserModalsSet {0}{1}' -f $computerName,[Environment]::NewLine
      switch ( $PSCmdlet.ParameterSetName ) {
        "AccountLockout" {
          $testMessage += '      USER_MODALS_INFO_3.usrmod3_lockout_duration = {0}{1}' -f $um.usrmod3_lockout_duration,[Environment]::NewLine
          $testMessage += '      USER_MODALS_INFO_3.usrmod3_lockout_observation_window = {0}{1}' -f $um.usrmod3_lockout_observation_window,[Environment]::NewLine
          $testMessage += '      USER_MODALS_INFO_3.usrmod3_lockout_threshold = {0}' -f $um.usrmod3_lockout_threshold
        }
        "MinimumPasswordLength" {
          $testMessage += '      USER_MODALS_INFO_1001.usrmod1001_min_passwd_len = {0}' -f $um.usrmod1001_min_passwd_len
        }
        "MaximumPasswordAge" {
          $testMessage += '      USER_MODALS_INFO_1002.usrmod1002_max_passwd_age = {0}' -f $um.usrmod1002_max_passwd_age
        }
        "MinimumPasswordAge" {
          $testMessage += '      USER_MODALS_INFO_1003.usrmod1003_min_passwd_age = {0}' -f $um.usrmod1003_min_passwd_age
        }
        "ForceLogoff" {
          $testMessage += '      USER_MODALS_INFO_1004.usrmod1004_force_logoff = {0}' -f $um.usrmod1004_force_logoff
        }
        "PasswordHistoryCount" {
          $testMessage += '      USER_MODALS_INFO_1005.usrmod1005_password_hist_len = {0}' -f $um.usrmod1005_password_hist_len
        }
      }
      Write-Host $testMessage -ForegroundColor $TEST_COLOR
    }
    if ( $result -ne $ERROR_SUCCESS ) {
      WriteCustomError $result $computerName -scope 3
    }
  }
  finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($bufPtr)
  }
  # SetNetLocalAccountPolicy terminates on first error; other callers can discard this
  $result
}

# Wrapper for NetUserModalsSet
function SetNetLocalAccountPolicy {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(ParameterSetName = "LockoutPolicy")]
    [UInt32]
    $lockoutDurationSeconds,

    [Parameter(ParameterSetName = "LockoutPolicy")]
    [UInt32]
    $lockoutObservationSeconds,

    [Parameter(ParameterSetName = "LockoutPolicy")]
    [UInt32]
    $lockoutThresholdCount,

    [Parameter(ParameterSetName = "OtherPolicies")]
    [UInt32]
    $minimumPasswordLength,

    [Parameter(ParameterSetName = "OtherPolicies")]
    [UInt32]
    $maximumPasswordAgeSeconds,

    [Parameter(ParameterSetName = "OtherPolicies")]
    [UInt32]
    $minimumPasswordAgeSeconds,

    [Parameter(ParameterSetName = "OtherPolicies")]
    [UInt32]
    $forceLogoffSeconds,

    [Parameter(ParameterSetName = "OtherPolicies")]
    [UInt32]
    $passwordHistoryCount
  )
  switch ( $PSCmdlet.ParameterSetName ) {
    "LockoutPolicy" {
      # These parameters must all be specified together
      $params = @{
        computerName = $computerName
        lockoutDurationSeconds = $lockoutDurationSeconds
        lockoutObservationSeconds = $lockoutObservationSeconds
        lockoutThresholdCount = $lockoutThresholdCount
      }
      $null = NetUserModalsSet @params
    }
    "OtherPolicies" {
      $otherPolicyParams = @(
        "minimumPasswordLength"
        "maximumPasswordAgeSeconds"
        "minimumPasswordAgeSeconds"
        "forceLogoffSeconds"
        "passwordHistoryCount"
      )
      foreach ( $psBoundParameter in $psBoundParameters.GetEnumerator() ) {
        $params = @{
          computerName = $computerName
        }
        if ( $otherPolicyParams -contains $psBoundParameter.Key ) {
          $params[$psBoundParameter.Key] = $psBoundParameter.Value
          if ( (NetUserModalsSet @params) -ne $ERROR_SUCCESS ) {
            break
          }
        }
      }
    }
  }
}

# API: NetUserSetInfo
# Module function(s): Set-NetLocalUser
# Input: Computer name, user name and other properties
# Output: Zero for success, non-zero for failure
function NetUserSetInfo {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $userName,

    [Parameter(ParameterSetName = "ChangePasswordAtLogon")]
    [Boolean]
    $changePasswordAtLogon,

    [Parameter(ParameterSetName = "Description")]
    [String]
    $description,

    [Parameter(ParameterSetName = "Enable")]
    [Boolean]
    $enabled,

    [Parameter(ParameterSetName = "FullName")]
    [String]
    $fullName,

    [Parameter(ParameterSetName = "Rename")]
    [String]
    $newName,

    [Parameter(ParameterSetName = "SetPassword")]
    [Security.SecureString]
    $password,

    [Parameter(ParameterSetName = "AccountExpires")]
    [DateTime]
    $accountExpires,

    [Parameter(ParameterSetName = "AccountNeverExpires")]
    [Boolean]
    $accountNeverExpires,

    [Parameter(ParameterSetName = "PasswordNeverExpires")]
    [Boolean]
    $passwordNeverExpires,

    [Parameter(ParameterSetName = "PasswordRequired")]
    [Boolean]
    $passwordRequired,

    [Parameter(ParameterSetName = "UserMayChangePassword")]
    [Boolean]
    $userMayChangePassword,

    [Parameter(ParameterSetName = "ProfilePath")]
    [String]
    $profilePath,

    [Parameter(ParameterSetName = "ScriptPath")]
    [String]
    $scriptPath,

    [Parameter(ParameterSetName = "HomeDrive")]
    [String]
    $homeDrive,

    [Parameter(ParameterSetName = "HomeDirectory")]
    [String]
    $homeDirectory
  )
  switch ( $PSCmdlet.ParameterSetName ) {
    "Description" {
      $level = 1007
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1007
      $ui.usri1007_comment = $description
    }
    "Enable" {
      # Retrieve existing flags so we can change appropriate bit
      $ui = NetUserGetInfo $computerName $userName -level 4
      if ( $null -eq $ui ) { return }
      $flags = $ui.usri4_flags
      $level = 1008
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1008
      if ( $enabled ) {
        $ui.usri1008_flags = $flags -band (-bnot $UF_ACCOUNTDISABLE)
      }
      else {
        $ui.usri1008_flags = $flags -bor $UF_ACCOUNTDISABLE
      }
    }
    "FullName" {
      $level = 1011
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1011
      $ui.usri1011_full_name = $fullName
    }
    "Rename" {
      $level = 0
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_0
      $ui.usri0_name = $newName
    }
    "SetPassword" {
      $level = 1003
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1003
      $ui.usri1003_password = ConvertToString $password
    }
    "ChangePasswordAtLogon" {
      $level = 4
      $ui = NetUserGetInfo $computerName $userName -level $level
      if ( $null -eq $ui ) { return }
      if ( $changePasswordAtLogon ) {
        # Clear PasswordNeverExpires and set UserMayChangePassword flags if
        # ChangePasswordAtLogon is enabled
        $ui.usri4_flags = $ui.usri4_flags -band (-bnot ($UF_DONT_EXPIRE_PASSWD -bor $UF_PASSWD_CANT_CHANGE))
      }
      $ui.usri4_password_expired = (0,1)[$changePasswordAtLogon]
    }
    "AccountExpires" {
      $level = 1017
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1017
      $seconds = ([DateTimeOffset] $accountExpires.ToUniversalTime()).ToUnixTimeSeconds()
      if ( $seconds -ge [UInt32]::MaxValue ) {
        $seconds = $TIMEQ_FOREVER
      }
      $ui.usri1017_acct_expires = $seconds
    }
    "AccountNeverExpires" {
      $level = 1017
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1017
      $ui.usri1017_acct_expires = $TIMEQ_FOREVER
    }
    "PasswordNeverExpires" {
      $level = 4
      $ui = NetUserGetInfo $computerName $userName -level $level
      if ( $null -eq $ui ) { return }
      if ( $passwordNeverExpires ) {
        # Clear ChangePasswordAtLogon if PasswordNeverExpires enabled
        $ui.usri4_password_expired = 0
        $ui.usri4_flags = $ui.usri4_flags -bor $UF_DONT_EXPIRE_PASSWD
      }
      else {
        $ui.usri4_flags = $ui.usri4_flags -band (-bnot $UF_DONT_EXPIRE_PASSWD)
      }
    }
    "PasswordRequired" {
      # Retrieve existing flags so we can change appropriate bit
      $ui = NetUserGetInfo $computerName $userName -level 4
      if ( $null -eq $ui ) { return }
      $flags = $ui.usri4_flags
      $level = 1008
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1008
      if ( $passwordRequired ) {
        $ui.usri1008_flags = $flags -band (-bnot $UF_PASSWD_NOTREQD)
      }
      else {
        $ui.usri1008_flags = $flags -bor $UF_PASSWD_NOTREQD
      }
    }
    "UserMayChangePassword" {
      $level = 4
      $ui = NetUserGetInfo $computerName $userName -level $level
      if ( $null -eq $ui ) { return }
      if ( $userMayChangePassword ) {
        $ui.usri4_flags = $ui.usri4_flags -band (-bnot $UF_PASSWD_CANT_CHANGE)
      }
      else {
        # Clear ChangePasswordAtLogon if UserMayChangePassword disabled
        $ui.usri4_password_expired = 0
        $ui.usri4_flags = $ui.usri4_flags -bor $UF_PASSWD_CANT_CHANGE
      }
    }
    "ProfilePath" {
      $level = 1052
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1052
      $ui.usri1052_profile = $profilePath
    }
    "ScriptPath" {
      $level = 1009
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1009
      $ui.usri1009_script_path = $scriptPath
    }
    "HomeDrive" {
      $level = 1053
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1053
      $ui.usri1053_home_dir_drive = $homeDrive
    }
    "HomeDirectory" {
      $level = 1006
      $ui = New-Object F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts+USER_INFO_1006
      $ui.usri1006_home_dir = $homeDirectory
    }
  }
  $parmErr = 0
  try {
    $bufPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal([Runtime.InteropServices.Marshal]::SizeOf($ui))
    [Runtime.InteropServices.Marshal]::StructureToPtr($ui,$bufPtr,$false)
    if ( -not $TEST_MODE ) {
      $result = [F5E1C3D31AC644ED981EAA159ADDD879.NetAccounts]::NetUserSetInfo(
        $computerName,  # servername
        $userName,      # username
        $level,         # level
        $bufPtr,        # buf
        [Ref] $parmErr  # parm_err
      )
    }
    else {
      $result = $ERROR_SUCCESS
      $testMessage = 'TEST: NetUserSetInfo {0} "{1}"{2}' -f $computerName,$userName,[Environment]::NewLine
      switch ( $PSCmdlet.ParameterSetName ) {
        "Description"           { $testMessage += '      USER_INFO_1007.usri1007_comment = {0}' -f $ui.usri1007_comment }
        "Enable"                { $testMessage += '      USER_INFO_1008.usri1008_flags = 0x{0:X8}' -f $ui.usri1008_flags }
        "FullName"              { $testMessage += '      USER_INFO_1011.usri1011_full_name = {0}' -f $ui.usri1011_full_name }
        "Rename"                { $testMessage += '      USER_INFO_0.usri0_name = {0}' -f $ui.usri0_name }
        "SetPassword"           { $testMessage += '      USER_INFO_1003.usri1003_password = {0}' -f $ui.usri1003_password }
        "ChangePasswordAtLogon" {
          $testmessage += '      USER_INFO_4.usri4_flags = 0x{0:X8}{1}' -f $ui.usri4_flags,[Environment]::NewLine
          $testMessage += '      USER_INFO_4.usri4_password_expired = 0x{0:X8}' -f $ui.usri4_password_expired
        }
        "PasswordNeverExpires" {
          $testMessage += '      USER_INFO_4.usri4_flags = 0x{0:X8}{1}' -f $ui.usri4_flags,[Environment]::NewLine
          $testMessage += '      USER_INFO_4.usri4_password_expired = 0x{0:X8}' -f $ui.usri4_password_expired
        }
        "PasswordRequired"      { $testMessage += '      USER_INFO_1008.usri1008_flags = 0x{0:X8}' -f $ui.usri1008_flags }
        "AccountExpires"        { $testMessage += '      USER_INFO_1017.usri1017_acct_expires = 0x{0:X8}' -f $ui.usri1017_acct_expires }
        "AccountNeverExpires"   { $testMessage += '      USER_INFO_1017.usri1017_acct_expires = 0x{0:X8}' -f $ui.usri1017_acct_expires }
        "UserMayChangePassword" {
          $testMessage += '      USER_INFO_4.usri4_flags = 0x{0:X8}{1}' -f $ui.usri4_flags,[Environment]::NewLine
          $testMessage += '      USER_INFO_4.usri4_password_expired = 0x{0:X8}' -f $ui.usri4_password_expired
        }
        "ProfilePath"           { $testMessage += '      USER_INFO_1052.usri1052_profile = {0}' -f $ui.usri1052_profile }
        "ScriptPath"            { $testMessage += '      USER_INFO_1009.usri1009_script_path = {0}' -f $ui.usri1009_script_path }
        "HomeDrive"             { $testMessage += '      USER_INFO_1053.usri1053_home_dir_drive = {0}' -f $ui.usri1053_home_dir_drive }
        "HomeDirectory"         { $testMessage += '      USER_INFO_1053.usri1006_home_dir = {0}' -f $ui.usri1006_home_dir }
      }
      Write-Host $testMessage -ForegroundColor $TEST_COLOR
    }
    if ( $result -ne $ERROR_SUCCESS ) {
      WriteCustomError $result (ResolveAccountName "$computerName\$userName") -scope 3
    }
  }
  finally {
    [Runtime.InteropServices.Marshal]::FreeHGlobal($bufPtr)
  }
  # SetNetUser terminates on first error; other callers can discard this
  $result
}

# Wrapper for Set-NetLocalUser that calls NetUserSetInfo once for each
# property; if any call to NetUserSetInfo fails, the function aborts
function SetNetLocalUser {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,Mandatory)]
    [String]
    $computerName,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $userName,

    [DateTime]
    $accountExpires,

    [Switch]
    $accountNeverExpires,

    [String]
    $description,

    [Boolean]
    $enabled,

    [String]
    $fullName,

    [String]
    $newName,

    [Security.SecureString]
    $password,

    [Boolean]
    $changePasswordAtLogon,

    [Boolean]
    $passwordNeverExpires,

    [Boolean]
    $passwordRequired,

    [Boolean]
    $userMayChangePassword,

    [String]
    $profilePath,

    [String]
    $scriptPath,

    [String]
    $homeDrive,

    [String]
    $homeDirectory
  )
  $validParams = @(
    "accountExpires"
    "accountNeverExpires"
    "description"
    "enabled"
    "fullName"
    "newName"
    "password"
    "changePasswordAtLogon"
    "passwordNeverExpires"
    "passwordRequired"
    "userMayChangePassword"
    "profilePath"
    "scriptPath"
    "homeDrive"
    "homeDirectory"
  )
  foreach ( $psBoundParameter in $PSBoundParameters.GetEnumerator() ) {
    $params = @{
      computerName = $computerName
      userName = $userName
    }
    if ( $validParams -contains $psBoundParameter.Key ) {
      $params[$psBoundParameter.Key] = $psBoundParameter.Value
      if ( (NetUserSetInfo @params) -ne $ERROR_SUCCESS ) {
        break
      }
    }
  }
}


# Exported module functions
# =============================================================================

# Uses: NetUserModalsGet
function Get-NetLocalAccountPolicy {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
  }
  process {
    foreach ( $computerNameItem in $ComputerName ) {
      if ( (TestDC $computerNameItem) -eq $ERROR_SUCCESS ) {
        NetUserModalsGet $computerNameItem -errorScope 2
      }
    }
  }
}

# Uses: NetLocalGroupEnum and NetLocalGroupGetInfo
function Get-NetLocalGroup {
  [CmdletBinding(DefaultParameterSetName = "Name")]
  param(
    [Parameter(ParameterSetName = "Name",Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [String]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
    $null = TestDC $ComputerName -terminatingError
    $validTypes = [NetPrincipalType]::BuiltinGroup,[NetPrincipalType]::LocalGroup
  }
  process {
    switch ( $PSCmdlet.ParameterSetName ) {
      "Name" {
        if ( -not $Name ) {
          NetLocalGroupEnum $ComputerName
        }
        else {
          foreach ( $nameItem in $Name ) {
            NetLocalGroupGetInfo $ComputerName $nameItem
          }
        }
      }
      "SID" {
        foreach ( $sidItem in $SID ) {
          $principal = LookupAccountSid $ComputerName $sidItem
          if ( $null -ne $principal ) {
            if ( ($validTypes -contains $principal.Type) -and ($principal.SID -eq $sidItem) ) {
              NetLocalGroupGetInfo $principal.ComputerName $principal.Name
            }
            else {
              WriteCustomError $CO_E_INVALIDSID $principal.SID.Value -scope 1
            }
          }
        }
      }
    }
  }
}

# Uses: NetUserModalsGet, NetQueryDisplayInformation, NetUserGetInfo
function Get-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "Name")]
  param(
    [Parameter(ParameterSetName = "Name",Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [String]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
    $null = TestDC $ComputerName -terminatingError
    $pwInfo = NetUserModalsGet $ComputerName -level 0 -errorScope 2
  }
  process {
    if ( $null -eq $pwInfo ) { return }
    switch ( $PSCmdlet.ParameterSetName ) {
      "Name" {
        if ( -not $Name ) {
          NetQueryDisplayInformation $ComputerName $pwInfo
        }
        else {
          foreach ( $nameItem in $Name ) {
            NetUserGetInfo $ComputerName $nameItem $pwInfo
          }
        }
      }
      "SID" {
        foreach ( $sidItem in $SID ) {
          $principal = LookupAccountSid $ComputerName $sidItem
          if ( $null -ne $principal ) {
            if ( ($principal.Type -eq [NetPrincipalType]::LocalUser) -and ($principal.SID -eq $sidItem) ) {
              NetUserGetInfo $principal.ComputerName $principal.Name $pwInfo
            }
            else {
              WriteCustomError $CO_E_INVALIDSID $principal.SID.Value -scope 1
            }
          }
        }
      }
    }
  }
}

# Uses: Get-NetLocalGroup
function Get-NetLocalAdminGroup {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
  }
  process {
    foreach ( $computerNameItem in $ComputerName ) {
      Get-NetLocalGroup -SID "S-1-5-32-544" -ComputerName $computerNameItem
    }
  }
}

# Uses: GetLocalAdminSID, Get-NetLocalUser
function Get-NetLocalAdminUser {
  [CmdletBinding()]
  param(
    [Parameter(Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
  }
  process {
    foreach ( $computerNameItem in $ComputerName ) {
      $localAdminSID = GetLocalAdminSID $computerNameItem
      if ( $null -ne $localAdminSID ) {
        Get-NetLocalUser -SID $localAdminSID -ComputerName $computerNameItem
      }
    }
  }
}

# Uses: LookupAccountName, LookupAccountSid, GetDomainAdminsSID
function Get-WellknownNetPrincipal {
  [CmdletBinding(DefaultParameterSetName = "Name")]
  param(
    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [Parameter(ParameterSetName = "DomainAdmins",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $DomainAdmins
  )
  begin {
    $validTypes = [NetPrincipalType]::BuiltinGroup,[NetPrincipalType]::WellKnown
  }
  process {
    switch ( $PSCmdlet.ParameterSetName ) {
      "Name" {
        foreach ( $nameItem in $Name ) {
          $principal = LookupAccountName ([Environment]::MachineName) $nameItem
          if ( $null -ne $principal ) {
            if ( $validTypes -contains $principal.Type ) {
              $principal
            }
            else {
              WriteCustomError $CO_E_NOMATCHINGSIDFOUND $principal.Name -scope 1
            }
          }
        }
      }
      "SID" {
        foreach ( $sidItem in $SID ) {
          $principal = LookupAccountSid ([Environment]::MachineName) $sidItem
          if ( $null -ne $principal ) {
            if ( $validTypes -contains $principal.Type ) {
              $principal
            }
            else {
              WriteCustomError $CO_E_INVALIDSID $principal.SID.Value -scope 1
            }
          }
        }
      }
      "DomainAdmins" {
        foreach ( $domainAdminsItem in $DomainAdmins ) {
          $domainAdminsSID = GetDomainAdminsSID $domainAdminsItem
          if ( $null -ne $domainAdminsSID ) {
            $principal = LookupAccountSid ([Environment]::MachineName) $domainAdminsSID
            if ( $null -ne $principal ) {
              if ( $principal.Type -eq [NetPrincipalType]::DomainGroup ) {
                $principal
              }
              else {
                WriteCustomError $CO_E_NOMATCHINGSIDFOUND $domainNameItem -scope 1
              }
            }
          }
        }
      }
    }
  }
}

# Uses: Get-NetLocalGroup, NetLocalGroupChangeMembers
function Add-NetLocalGroupMember {
  [CmdletBinding(DefaultParameterSetName = "Group",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "Group",Position = 0,Mandatory)]
    [NetLocalGroupPrincipal]
    $Group,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory)]
    [Security.Principal.SecurityIdentifier]
    $SID,

    [Parameter(Position = 1,Mandatory,ValueFromPipeline)]
    [NetPrincipal[]]
    $Member,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    $params = @{
      action = "Add"
    }
    if ( $PSBoundParameters.ContainsKey("Group") ) {
      $params["computerName"] = ([Environment]::MachineName,$Group.ComputerName)[[Boolean] $Group.ComputerName]
      $groupPrincipal = $Group
    }
    else {
      $params["computerName"] = ([Environment]::MachineName,$ComputerName)[[Boolean] $ComputerName]
    }
    $null = TestDC $params["computerName"] -terminatingError
    SetTestMode -Confirm:$false -WhatIf:$false
    if ( $PSBoundParameters.ContainsKey("Name") ) {
      $groupPrincipal = Get-NetLocalGroup $Name -ComputerName $params["computerName"]
    }
    elseif ( $PSBoundParameters.ContainsKey("SID") ) {
      $groupPrincipal = Get-NetLocalGroup -SID $SID -ComputerName $params["computerName"]
    }
  }
  process {
    if ( -not $groupPrincipal ) { return }
    $target = "{0}\{1}" -f $groupPrincipal.ComputerName,$groupPrincipal.Name
    $params["groupName"] = $groupPrincipal.Name
    foreach ( $memberItem in $Member ) {
      $memberPrincipal = ResolvePrincipal $memberItem $groupPrincipal.ComputerName
      if ( $null -eq $memberPrincipal ) { continue }
      $action = "{0} member '{1}'" -f $Params["action"],
        (ResolveAccountName ("{0}\{1}" -f $memberPrincipal.AuthorityName,$memberPrincipal.Name))
      if ( $PSCmdlet.ShouldProcess($target,$action) ) {
        $params["sid"] = $memberPrincipal.SID
        try {
          NetLocalGroupChangeMembers @params
        }
        catch {
          WriteCustomError -errorRecord $_ -scope 1
        }
      }
    }
  }
}

# Uses: Get-NetLocalGroup, NetLocalGroupChangeMembers
function Remove-NetLocalGroupMember {
  [CmdletBinding(DefaultParameterSetName = "Group",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "Group",Position = 0,Mandatory)]
    [NetLocalGroupPrincipal]
    $Group,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory)]
    [Security.Principal.SecurityIdentifier]
    $SID,

    [Parameter(Position = 1,Mandatory,ValueFromPipeline)]
    [NetPrincipal[]]
    $Member,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    $params = @{
      action = "Remove"
    }
    if ( $PSBoundParameters.ContainsKey("Group") ) {
      $params["computerName"] = ([Environment]::MachineName,$Group.ComputerName)[[Boolean] $Group.ComputerName]
      $groupPrincipal = $Group
    }
    else {
      $params["computerName"] = ([Environment]::MachineName,$ComputerName)[[Boolean] $ComputerName]
    }
    $null = TestDC $params["computerName"] -terminatingError
    SetTestMode -Confirm:$false -WhatIf:$false
    if ( $PSBoundParameters.ContainsKey("Name") ) {
      $groupPrincipal = Get-NetLocalGroup $Name -ComputerName $params["computerName"]
    }
    elseif ( $PSBoundParameters.ContainsKey("SID") ) {
      $groupPrincipal = Get-NetLocalGroup -SID $SID -ComputerName $params["computerName"]
    }
  }
  process {
    if ( -not $groupPrincipal ) { return }
    $target = "{0}\{1}" -f $groupPrincipal.ComputerName,$groupPrincipal.Name
    $params["groupName"] = $groupPrincipal.Name
    foreach ( $memberItem in $Member ) {
      $memberPrincipal = ResolvePrincipal $memberItem $groupPrincipal.ComputerName
      if ( $null -eq $memberPrincipal ) { continue }
      $action = "{0} member '{1}'" -f $Params["action"],
        (ResolveAccountName ("{0}\{1}" -f $memberPrincipal.AuthorityName,$memberPrincipal.Name))
      if ( $PSCmdlet.ShouldProcess($target,$action) ) {
        $params["sid"] = $memberPrincipal.SID
        try {
          NetLocalGroupChangeMembers @params
        }
        catch {
          WriteCustomError -errorRecord $_ -scope 1
        }
      }
    }
  }
}

# Uses: Get-NetLocalUser, NetUserSetInfo
function Disable-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalUserPrincipal[]]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    $action = "Disable local user account"
    $enable = $false
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    $inputValues = Get-Variable $PSCmdlet.ParameterSetName | Select-Object -ExpandProperty Value
    foreach ( $inputValue in $inputValues ) {
      switch ( $PSCmdlet.ParameterSetName ) {
        "InputObject" {
          $principal = ($inputValue,$null)[(TestDC $inputValue.ComputerName) -ne $ERROR_SUCCESS]
        }
        "Name" {
          $principal = Get-NetLocalUser $inputValue -ComputerName $ComputerName
        }
        "SID" {
          $principal = Get-NetLocalUser -SID $inputValue -ComputerName $ComputerName
        }
      }
      if ( $null -ne $principal ) {
        $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
        if ( $PSCmdlet.ShouldProcess($target,$action) ) {
          $null = NetUserSetInfo $principal.ComputerName $principal.Name -enabled $enable
        }
      }
    }
  }
}

# Uses: Get-NetLocalUser, NetUserSetInfo
function Enable-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalUserPrincipal[]]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    $action = "Enable local user account"
    $enable = $true
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    $inputValues = Get-Variable $PSCmdlet.ParameterSetName | Select-Object -ExpandProperty Value
    foreach ( $inputValue in $inputValues ) {
      switch ( $PSCmdlet.ParameterSetName ) {
        "InputObject" {
          $principal = ($inputValue,$null)[(TestDC $inputValue.ComputerName) -ne $ERROR_SUCCESS]
        }
        "Name" {
          $principal = Get-NetLocalUser $inputValue -ComputerName $ComputerName
        }
        "SID" {
          $principal = Get-NetLocalUser -SID $inputValue -ComputerName $ComputerName
        }
      }
      if ( $null -ne $principal ) {
        $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
        if ( $PSCmdlet.ShouldProcess($target,$action) ) {
          $null = NetUserSetInfo $principal.ComputerName $principal.Name -enabled $enable
        }
      }
    }
  }
}

# Uses: Get-NetLocalGroup, NetLocalGroupGetMembers
function Get-NetLocalGroupMember {
  [CmdletBinding(DefaultParameterSetName = "Group")]
  param(
    [Parameter(ParameterSetName = "Group",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalGroupPrincipal[]]
    $Group,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
    $null = TestDC $ComputerName -terminatingError
  }
  process {
    $inputValues = Get-Variable $PSCmdlet.ParameterSetName | Select-Object -ExpandProperty Value
    foreach ( $inputValue in $inputValues ) {
      switch ( $PSCmdlet.ParameterSetName ) {
        "Group" {
          $principal = ($inputValue,$null)[(TestDC $inputValue.ComputerName) -ne $ERROR_SUCCESS]
        }
        "Name" {
          $principal = Get-NetLocalGroup $inputValue -ComputerName $ComputerName
        }
        "SID" {
          $principal = Get-NetLocalGroup -SID $inputValue -ComputerName $ComputerName
        }
      }
      if ( $null -ne $principal ) {
        NetLocalGroupGetMembers $principal.ComputerName $principal.Name
      }
    }
  }
}

# Uses: NetLocalGroupAdd, Get-NetLocalGroup
function New-NetLocalGroup {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Position = 0,Mandatory,ValueFromPipeline)]
    [String]
    $Name,

    [String]
    $Description,

    [String]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
    $null = TestDC $ComputerName -terminatingError
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    $action = "Create local security group '{0}'" -f $Name
    if ( $PSCmdlet.ShouldProcess($ComputerName,$action) ) {
      if ( (NetLocalGroupAdd $ComputerName $Name $Description) -eq $ERROR_SUCCESS ) {
        if ( -not $TEST_MODE ) {
          Get-NetLocalGroup $Name -ComputerName $ComputerName
        }
      }
    }
  }
}

# Uses: NetUserAdd, Get-NetLocalUser
function New-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "Password",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "Password",Position = 0,Mandatory,ValueFromPipeline)]
    [Parameter(ParameterSetName = "NoPassword",Position = 0,Mandatory,ValueFromPipeline)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "NoPassword",Mandatory)]
    [Switch]
    $NoPassword,

    [Parameter(ParameterSetName = "Password",Mandatory)]
    [Security.SecureString]
    $Password,

    [DateTime]
    $AccountExpires,

    [Switch]
    $ChangePasswordAtLogon,

    [String]
    $Description,

    [Switch]
    $Disabled,

    [String]
    $FullName,

    [Switch]
    $PasswordNeverExpires,

    [Switch]
    $PasswordRequired,

    [Switch]
    $UserMayNotChangePassword,

    [String]
    $ProfilePath,

    [String]
    $ScriptPath,

    [String]
    $HomeDrive,

    [String]
    $HomeDirectory,

    [String]
    $ComputerName
  )
  begin {
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
    $null = TestDC $ComputerName -terminatingError
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    $validParams = @(
      "Password"
      "NoPassword"
      "AccountExpires"
      "Description"
      "Disabled"
      "FullName"
      "PasswordNeverExpires"
      "PasswordRequired"
      "UserMayNotChangePassword"
      "ProfilePath"
      "ScriptPath"
      "HomeDrive"
      "HomeDirectory"
    )
    $params = @{}
    foreach ( $psBoundParameter in $PSBoundParameters.GetEnumerator() ) {
      if ( $validParams -contains $psBoundParameter.Key ) {
        # -HomeDirectory and -ProfilePath support %username% replacement
        if ( ($psBoundParameter.Key -eq "HomeDirectory") -or ($psBoundParameter.Key -eq "ProfilePath") ) {
          $params[$psBoundParameter.Key] = $psBoundParameter.Value -replace '%username%',$Name
        }
        else {
          $params[$psBoundParameter.Key] = $psBoundParameter.Value
        }
      }
    }
    $params["userName"] = $Name
    if ( $params["AccountExpires"] -gt $LatestDateTimeOffset.ToLocalTime().LocalDateTime ) {
      WriteCustomError $ERROR_INVALID_TIME -scope 1 -terminatingError
    }
    if ( -not $PSBoundParameters.ContainsKey("ChangePasswordAtLogon") ) {
      $params["passwordNeverExpires"] = $PasswordNeverExpires
      $params["userMayNotChangePassword"] = $UserMayNotChangePassword
      # -ChangePasswordAtLogon not specified; disable if we got either
      # -PasswordNeverExpires or -UserMayNotChangePassword, or enable otherwise
      $params["changePasswordAtLogon"] = ($true,$false)[$params["PasswordNeverExpires"] -or $params["UserMayNotChangePassword"]]
    }
    else {
      $params["changePasswordAtLogon"] = $ChangePasswordAtLogon
    }
    if ( $params["changePasswordAtLogon"] -and ($params["PasswordNeverExpires"] -or $params["UserMayNotChangePassword"]) ) {
      WriteCustomError $ERROR_INVALID_PARAMETER 'You cannot specifty -ChangePasswordAtLogon with -PasswordNeverExpires or -UserMayNotChangePassword.' -scope 1 -terminatingError
    }
    # -PasswordRequired default is $true
    $params["passwordRequired"] = ($true,$PasswordRequired)[$PSBoundParameters.ContainsKey("PasswordRequired")]
    $params["computerName"] = $ComputerName
    $action = "Create local user account '{0}'" -f $params["userName"]
    if ( $PSCmdlet.ShouldProcess($params["computerName"],$action) ) {
      if ( (NetUserAdd @params) -eq $ERROR_SUCCESS ) {
        if ( -not $TEST_MODE ) {
          Get-NetLocalUser $params["userName"] -ComputerName $params["ComputerName"]
        }
      }
    }
  }
}

# Uses: Get-NetLocalGroup, NetLocalGroupDel
function Remove-NetLocalGroup {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess,ConfirmImpact = "High")]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalGroupPrincipal[]]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    $action = "Remove local security group"
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    $inputValues = Get-Variable $PSCmdlet.ParameterSetName | Select-Object -ExpandProperty Value
    foreach ( $inputValue in $inputValues ) {
      switch ( $PSCmdlet.ParameterSetName ) {
        "InputObject" {
          $principal = ($inputValue,$null)[(TestDC $inputValue.ComputerName) -ne $ERROR_SUCCESS]
        }
        "Name" {
          $principal = Get-NetLocalGroup $inputValue -ComputerName $ComputerName
        }
        "SID" {
          $principal = Get-NetLocalGroup -SID $inputValue -ComputerName $ComputerName
        }
      }
      if ( $null -ne $principal ) {
        $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
        if ( $PSCmdlet.ShouldProcess($target,$action) ) {
          NetLocalGroupDel $principal.ComputerName $principal.Name
        }
      }
    }
  }
}

# Uses: Get-NetLocalUser, NetUserDel
function Remove-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess,ConfirmImpact = "High")]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalUserPrincipal[]]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier[]]
    $SID,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    $action = "Remove local user account"
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    $inputValues = Get-Variable $PSCmdlet.ParameterSetName | Select-Object -ExpandProperty Value
    foreach ( $inputValue in $inputValues ) {
      switch ( $PSCmdlet.ParameterSetName ) {
        "InputObject" {
          $principal = ($inputValue,$null)[(TestDC $inputValue.ComputerName) -ne $ERROR_SUCCESS]
        }
        "Name" {
          $principal = Get-NetLocalUser $inputValue -ComputerName $ComputerName
        }
        "SID" {
          $principal = Get-NetLocalUser -SID $inputValue -ComputerName $ComputerName
        }
      }
      if ( $null -ne $principal ) {
        $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
        if ( $PSCmdlet.ShouldProcess($target,$action) ) {
          NetUserDel $principal.ComputerName $principal.Name
        }
      }
    }
  }
}

# Uses: Get-NetLocalGroup, NetLocalGroupSetInfo
function Rename-NetLocalGroup {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalGroupPrincipal]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier]
    $SID,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $NewName,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    switch ( $PSCmdlet.ParameterSetName ) {
      "InputObject" {
        $principal = ($InputObject,$null)[(TestDC $InputObject.ComputerName) -ne $ERROR_SUCCESS]
      }
      "Name" {
        $principal = Get-NetLocalGroup $Name -ComputerName $ComputerName
      }
      "SID" {
        $principal = Get-NetLocalGroup -SID $SID -ComputerName $ComputerName
      }
    }
    if ( $null -eq $Principal ) {
      return
    }
    $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
    if ( $PSCmdlet.ShouldProcess($target,"Rename local security group to '$NewName'") ) {
      $null = NetLocalGroupSetInfo $principal.ComputerName $principal.Name -newName $NewName
    }
  }
}

# Uses: Get-NetLocalUser, NetUserSetInfo
function Rename-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalUserPrincipal]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier]
    $SID,

    [Parameter(Position = 1,Mandatory)]
    [String]
    $NewName,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    switch ( $PSCmdlet.ParameterSetName ) {
      "InputObject" {
        $principal = ($InputObject,$null)[(TestDC $InputObject.ComputerName) -ne $ERROR_SUCCESS]
      }
      "Name" {
        $principal = Get-NetLocalUser $Name -ComputerName $ComputerName
      }
      "SID" {
        $principal = Get-NetLocalUser -SID $SID -ComputerName $ComputerName
      }
    }
    if ( $null -eq $Principal ) {
      return
    }
    $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
    if ( $PSCmdlet.ShouldProcess($target,"Rename local user account to '$NewName'") ) {
      $null = NetUserSetInfo $principal.ComputerName $principal.Name -newName $NewName
    }
  }
}

# Uses: Get-NetLocalGroup, NetLocalGroupSetInfo
function Set-NetLocalGroup {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalGroupPrincipal]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier]
    $SID,

    [Parameter(Mandatory)]
    [String]
    $Description,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
      $null = TestDC $ComputerName -terminatingError
    }
    switch ( $PSCmdlet.ParameterSetName ) {
      "InputObject" {
        $principal = ($InputObject,$null)[(TestDC $InputObject.ComputerName) -ne $ERROR_SUCCESS]
      }
      "Name" {
        $principal = Get-NetLocalGroup $Name -ComputerName $ComputerName
      }
      "SID" {
        $principal = Get-NetLocalGroup -SID $SID -ComputerName $ComputerName
      }
    }
    if ( $null -eq $principal ) {
      return
    }
    $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
    if ( $PSCmdlet.ShouldProcess($target,"Modify local security group") ) {
      $null = NetLocalGroupSetInfo $principal.ComputerName $principal.Name -description $Description
    }
  }
}

# Uses: Get-NetLocalUser, SetNetLocalUser
function Set-NetLocalUser {
  [CmdletBinding(DefaultParameterSetName = "InputObject",SupportsShouldProcess)]
  param(
    [Parameter(ParameterSetName = "InputObject",Position = 0,Mandatory,ValueFromPipeline)]
    [NetLocalUserPrincipal]
    $InputObject,

    [Parameter(ParameterSetName = "Name",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String]
    $Name,

    [Parameter(ParameterSetName = "SID",Position = 0,Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Security.Principal.SecurityIdentifier]
    $SID,

    [DateTime]
    $AccountExpires,

    [Switch]
    $AccountNeverExpires,

    [Boolean]
    $ChangePasswordAtLogon,

    [String]
    $Description,

    [String]
    $FullName,

    [Security.SecureString]
    $Password,

    [Boolean]
    $PasswordNeverExpires,

    [Boolean]
    $PasswordRequired,

    [Boolean]
    $UserMayChangePassword,

    [String]
    $ProfilePath,

    [String]
    $ScriptPath,

    [String]
    $HomeDrive,

    [String]
    $HomeDirectory,

    [Parameter(ParameterSetName = "Name")]
    [Parameter(ParameterSetName = "SID")]
    [String]
    $ComputerName
  )
  begin {
    SetTestMode -Confirm:$false -WhatIf:$false
  }
  process {
    $params = @{}
    if ( $PSCmdlet.ParameterSetName -ne "InputObject" ) {
      $params["computerName"] = ([Environment]::MachineName,$ComputerName)[[Boolean] $ComputerName]
      $null = TestDC $params["computerName"] -terminatingError
    }
    switch ( $PSCmdlet.ParameterSetName ) {
      "InputObject" {
        $principal = ($InputObject,$null)[(TestDC $InputObject.ComputerName) -ne $ERROR_SUCCESS]
        $params["computerName"] = $InputObject.ComputerName
      }
      "Name" {
        $principal = Get-NetLocalUser $Name -ComputerName $ComputerName
      }
      "SID" {
        $principal = Get-NetLocalUser -SID $SID -ComputerName $ComputerName
      }
    }
    if ( $null -eq $principal ) {
      return
    }
    if ( $PSBoundParameters.ContainsKey("AccountExpires") -and $AccountNeverExpires ) {
      WriteCustomError $ERROR_INVALID_PARAMETER 'You cannot specify both -AccountExpires and -AccountNeverExpires.' -scope 1 -terminatingError
    }
    if ( $ChangePasswordAtLogon -and ($PasswordNeverExpires -or
      ($PSBoundParameters.ContainsKey("UserMayChangePassword") -and (-not $UserMayChangePassword))) ) {
      WriteCustomError $ERROR_INVALID_PARAMETER 'You cannot specify "-ChangePasswordAtLogon $true" with either "-PasswordNeverExpires $true" or "-UserMayChangePassword $false."' -scope 1 -terminatingError
    }
    $ValidParams = @(
      "AccountExpires"
      "AccountNeverExpires"
      "ChangePasswordAtLogon"
      "Description"
      "FullName"
      "Password"
      "PasswordNeverExpires"
      "PasswordRequired"
      "UserMayChangePassword"
      "ProfilePath"
      "ScriptPath"
      "HomeDrive"
      "HomeDirectory"
    )
    foreach ( $psBoundParameter in $PSBoundParameters.GetEnumerator() ) {
      if ( $ValidParams -contains $psBoundParameter.Key ) {
        # -HomeDirectory and -ProfilePath support %username% replacement
        if ( ($psBoundParameter.Key -eq "HomeDirectory") -or ($psBoundParameter.Key -eq "ProfilePath") ) {
          $params[$psBoundParameter.Key] = $psBoundParameter.Value -replace '%username%',$principal.Name
        }
        else {
          $params[$psBoundParameter.Key] = $psBoundParameter.Value
        }
      }
    }
    if ( ($null -ne $params["AccountExpires"]) -and ($params["AccountExpires"] -gt $LatestDateTimeOffset.ToLocalTime().LocalDateTime) ) {
      WriteCustomError $ERROR_INVALID_TIME -scope 1 -terminatingError
    }
    $params["userName"] = $principal.Name
    $target = "{0}\{1}" -f $principal.ComputerName,$principal.Name
    if ( $PSCmdlet.ShouldProcess($target,"Modify local user account") ) {
      SetNetLocalUser @params
    }
  }
}

# Uses: SetNetLocalAccountPolicy
function Set-NetLocalAccountPolicy {
  [CmdletBinding(SupportsShouldProcess,ConfirmImpact = "High")]
  param(
    [Parameter(Position = 0,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [String[]]
    $ComputerName,

    [Parameter(ParameterSetName = "NoAccountLockout",Mandatory)]
    [Switch]
    $NoAccountLockout,

    [Parameter(ParameterSetName = "AccountLockout",Mandatory)]
    [Int]
    [ValidateRange(0,99999)]
    $LockoutDurationMinutes,

    [Parameter(ParameterSetName = "AccountLockout",Mandatory)]
    [Int]
    [ValidateRange(1,99999)]
    $LockoutObservationMinutes,

    [Parameter(ParameterSetName = "AccountLockout",Mandatory)]
    [Int]
    [ValidateRange(1,999)]
    $LockoutThresholdCount,

    [Parameter(ParameterSetName = "MinimumPasswordLength",Mandatory)]
    [Int]
    [ValidateRange(0,14)]
    $MinimumPasswordLength,

    [Parameter(ParameterSetName = "PasswordsNeverExpire",Mandatory)]
    [Switch]
    $PasswordsNeverExpire,

    [Parameter(ParameterSetName = "MaximumPasswordAge",Mandatory)]
    [Int]
    [ValidateRange(1,999)]
    $MaximumPasswordAgeDays,

    [Parameter(ParameterSetName = "MinimumPasswordAge",Mandatory)]
    [Int]
    [ValidateRange(0,999)]
    $MinimumPasswordAgeDays,

    [Parameter(ParameterSetName = "PasswordHistoryCount",Mandatory)]
    [Int]
    [ValidateRange(0,8)]
    $PasswordHistoryCount,

    [Parameter(ParameterSetName = "NoForceLogoff",Mandatory)]
    [Switch]
    $NoForceLogoff,

    [Parameter(ParameterSetName = "ForceLogoff",Mandatory)]
    [Int]
    [ValidateRange(0,999)]
    $ForceLogoffMinutes
  )
  begin {
    SetTestMode -Confirm:$false -WhatIf:$false
    if ( -not $ComputerName ) { $ComputerName = [Environment]::MachineName }
  }
  process {
    foreach ( $computerNameItem in $ComputerName ) {
      $null = TestDC $computerNameItem -terminatingError
      $params = @{
        "computerName" = $computerNameItem
      }
      switch ( $PSCmdlet.ParameterSetName ) {
        "NoAccountLockout" {
          $params["lockoutDurationSeconds"] = 0
          $params["lockoutObservationSeconds"] = 0
          $params["lockoutThresholdCount"] = 0
        }
        "AccountLockout" {
          if ( $LockoutDurationMinutes -lt $LockoutObservationMinutes ) {
            WriteCustomError $ERROR_INVALID_PARAMETER "-LockoutDurationMinutes must be greater than or equal to -LockoutObservationMinutes." -scope 1 -terminatingError
            return
          }
          $params["lockoutDurationSeconds"] = $LockoutDurationMinutes * 60
          $params["lockoutObservationSeconds"] = $LockoutObservationMinutes * 60
          $params["lockoutThresholdCount"] = $LockoutThresholdCount
        }
        "MinimumPasswordLength" {
          $params["minimumPasswordLength"] = $MinimumPasswordLength
        }
        "PasswordsNeverExpire" {
          $params["maximumPasswordAgeSeconds"] = $TIMEQ_FOREVER
        }
        "MaximumPasswordAge" {
          $params["maximumPasswordAgeSeconds"] = $MaximumPasswordAgeDays * 86400
        }
        "MinimumPasswordAge" {
          $params["minimumPasswordAgeSeconds"] = $MinimumPasswordAgeDays * 86400
        }
        "PasswordHistoryCount" {
          $params["passwordHistoryCount"] = $PasswordHistoryCount
        }
        "NoForceLogoff" {
          $params["forceLogoffSeconds"] = $TIMEQ_FOREVER
        }
        "ForceLogoff" {
          $params["forceLogoffSeconds"] = $ForceLogoffMinutes * 60
        }
      }
      if ( ($params.Count -gt 1) -and $PSCmdlet.ShouldProcess($computerNameItem,"Modify local account policy") ) {
        SetNetLocalAccountPolicy @params
      }
    }
  }
}
