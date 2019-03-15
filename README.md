# Intune Backup & Restore
This PowerShell Module queries Microsoft Graph, and allows for cross-tenant Backup & Restore actions of your Intune Configuration.

Intune Configuration is backed up as (json) files in a given directory.

## Prerequisites
Requires AzureAD Module (`Install-Module -Name AzureAD`)  
Requires [MSGraphFunctions](https://github.com/jseerden/MSGraphFunctions) PowerShell Module  
Connect to Microsoft Graph using the `Connect-Graph` PSCmdlet first.

## Features

### Backup actions
- Client App Assignments
- Device Compliance Policies
- Device Compliance Policy Assignments
- Device Configurations
- Device Configuration Assignments
- Device Management Scripts (Device Configuration -> PowerShell Scripts)
- Device Management Script Assignments
- Software Update Rings
- Software Update Ring Assignments

### Restore actions
- Client App Assignments
- Device Compliance Policies
- Device Compliance Policy Assignments
- Device Configurations
- Device Configuration Assignments
- Device Management Scripts (Device Configuration -> PowerShell Scripts)
- Device Management Script Assignments
- Software Update Rings
- Software Update Ring Assignments

## Examples

### Example 01 - Full Intune Backup
```powershell
Start-BackupIntuneFull -Path C:\temp\IntuneBackup
```

### Example 02 - Full Intune Restore (excluding Assignments)
```powershell
Start-RestoreIntuneConfig -Path C:\temp\IntuneBackup
```

### Example 03 - Restore Intune Assignments 
If configurations have been restored:
```powershell
Start-RestoreIntuneConfig -Path C:\temp\IntuneBackup
```

If reassigning assignments to existing configurations. In this case the assignments match the configuration id to restore to.
```powershell
Start-RestoreIntuneAssignments -Path C:\temp\IntuneBackup -RestoreById $true
```

### Example 04 - Restore only Intune Compliance Policies

```powershell
Invoke-RestoreDeviceCompliancePolicy -Path C:\temp\IntuneBackup
```

```powershell
Invoke-RestoreDeviceCompliancePolicyAssignments -Path C:\temp\IntuneBackup -RestoreById $false
```

### Example 05 - Restore Only Intune Device Configurations
```powershell
Invoke-RestoreDeviceConfiguration -Path C:\temp\IntuneBackup
```

```powershell
Invoke-RestoreDeviceConfigurationAssignments -Path C:\temp\IntuneBackup -RestoreById $false
```

## Known Issues
- Does not support backing up Intune configuration items with duplicate Display Names. Files may be overwritten.
- Unable to restore Client App Assignments for Windows Line-of-Business Apps (MSI)
