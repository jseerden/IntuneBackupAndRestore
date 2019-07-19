# Intune Backup & Restore

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/IntuneBackupAndRestore.svg?label=PSGallery%20Version&logo=PowerShell&style=flat-square)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/IntuneBackupAndRestore.svg?label=PSGallery%20Downloads&logo=PowerShell&style=flat-square)


This PowerShell Module queries Microsoft Graph, and allows for cross-tenant Backup & Restore actions of your Intune Configuration.

Intune Configuration is backed up as (json) files in a given directory.

## Installing IntuneBackupAndRestore

```powershell
# Install IntuneBackupAndRestore from the PowerShell Gallery
Install-Module -Name IntuneBackupAndRestore
```

## Prerequisites
- Requires AzureAD PowerShell Module (`Install-Module -Name AzureAD`)  
- Requires [MSGraphFunctions](https://github.com/jseerden/MSGraphFunctions) PowerShell Module (`Install-Module -Name MSGraphFunctions`)
- Connect to Microsoft Graph using the `Connect-Graph` PSCmdlet first.

## Features

### Backup actions
- Administrative Templates (Device Configurations)
- Administrative Template Assignments
- Client Apps
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
- Administrative Templates (Device Configurations)
- Administrative Template Assignments
- Client App Assignments
- Device Compliance Policies
- Device Compliance Policy Assignments
- Device Configurations
- Device Configuration Assignments
- Device Management Scripts (Device Configuration -> PowerShell Scripts)
- Device Management Script Assignments
- Software Update Rings
- Software Update Ring Assignments

> Please note that some Client App settings can be backed up, for instance the retrieval of Win32 (un)install cmdlets, requirements, etcetera. The Client App itself is not backed up and this module does not support restoring Client Apps at this time.

## Examples

### Example 01 - Full Intune Backup
```powershell
Start-IntuneBackup -Path C:\temp\IntuneBackup
```

### Example 02 - Full Intune Restore
```powershell
Start-IntuneRestoreConfig -Path C:\temp\IntuneBackup
Start-IntuneRestoreAssignments -Path C:\temp\IntuneBackup
```

### Example 03 - Restore Intune Assignments 
If configurations have been restored:
```powershell
Start-IntuneRestoreAssignments -Path C:\temp\IntuneBackup
```

If reassigning assignments to existing (non-restored) configurations. In this case the assignments match the configuration id to restore to.  
This allows for restoring if display names have changed.
```powershell
Start-IntuneRestoreAssignments -Path C:\temp\IntuneBackup -RestoreById $true
```

### Example 04 - Restore only Intune Compliance Policies

```powershell
Invoke-IntuneRestoreDeviceCompliancePolicy -Path C:\temp\IntuneBackup
```

```powershell
Invoke-IntuneRestoreDeviceCompliancePolicyAssignments -Path C:\temp\IntuneBackup
```

### Example 05 - Restore Only Intune Device Configurations
```powershell
Invoke-IntuneRestoreDeviceConfiguration -Path C:\temp\IntuneBackup
```

```powershell
Invoke-IntuneRestoreDeviceConfigurationAssignments -Path C:\temp\IntuneBackup
```

### Example 06 - Compare two Backup Files for changes
```powershell
# The DifferenceFilePath should point to the latest Intune Backup file, as it might contain new properties.
Compare-IntuneBackupFile -ReferenceFilePath 'C:\temp\IntuneBackup\Device Configurations\Windows - Endpoint Protection.json' -DifferenceFilePath 'C:\temp\IntuneBackupLatest\Device Configurations\Windows - Endpoint Protection.json'
```

## Known Issues
- Does not support backing up Intune configuration items with duplicate Display Names. Files may be overwritten.
- Unable to restore Client App Assignments for Windows Line-of-Business Apps (MSI)
