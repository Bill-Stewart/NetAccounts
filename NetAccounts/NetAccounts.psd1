@{
  RootModule = 'NetAccounts.psm1'
  ModuleVersion = '0.0.2'
  GUID = '31df095b-3e4b-485c-ad3a-b12e746e0bf6'
  Author = 'Bill Stewart'
  CompanyName = 'Bill Stewart'
  Copyright = '(C) 2025 by Bill Stewart'
  Description = 'Manages local security groups and local user accounts on local and remote Windows computers.'
  CompatiblePSEditions = @('Desktop','Core')
  PowerShellVersion = '5.1'
  AliasesToExport = '*'
  FormatsToProcess = 'NetAccounts.format.ps1xml'
  FunctionsToExport = @(
    'Add-NetLocalGroupMember'
    'Disable-NetLocalUser'
    'Enable-NetLocalUser'
    'Get-NetLocalAdminGroup'
    'Get-NetLocalAdminUser'
    'Get-NetLocalGroup'
    'Get-NetLocalGroupMember'
    'Get-NetLocalUser'
    'Get-WellknownNetPrincipal'
    'New-NetLocalGroup'
    'New-NetLocalUser'
    'Remove-NetLocalGroup'
    'Remove-NetLocalGroupMember'
    'Remove-NetLocalUser'
    'Rename-NetLocalGroup'
    'Rename-NetLocalUser'
    'Set-NetLocalGroup'
    'Set-NetLocalUser'
  )
  PrivateData = @{
    PSData = @{
      # PowerShell Gallery tags
      Tags = @('account','management','local','Microsoft','Windows','LocalAccounts','PSEdition_Core','PSEdition_Desktop')
      LicenseUri = 'https://github.com/Bill-Stewart/NetAccounts/blob/master/LICENSE.txt'
      ProjectUri = 'https://github.com/Bill-Stewart/NetAccounts'
    }
  }
}
