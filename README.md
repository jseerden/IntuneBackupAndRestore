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
As of version 2.0.0, the IntuneBackupAndRestore PowerShell Module has migrated from the MSGraphFunctions PowerShell module to the Microsoft.Graph.Intune PowerShell module. Please make sure you meet the prerequisites below.

- Requires [Microsoft.Graph.Intune](https://github.com/Microsoft/Intune-PowerShell-SDK/) PowerShell Module (`Install-Module -Name Microsoft.Graph.Intune`)
- Connect to Microsoft Graph using the `Connect-MSGraph` PSCmdlet first.
- Make sure to import the IntuneBackupAndRestore PowerShell module before using it with the `Import-Module IntuneBackupAndRestore` cmdlet.

## Features

### Backup actions
- Administrative Templates (Device Configurations)
- Administrative Template Assignments
- App Protection Policies
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
- Endpoint Security Configurations
  - Security Baselines
    - Windows 10 Security Baselines
    - Microsoft Defender ATP Baselines
    - Microsoft Edge Baseline
  - Antivirus
  - Disk encryption
  - Firewall
  - Endpoint detection and response
  - Attack surface reduction
  - Account protection
  - Device compliance

### Restore actions
- Administrative Templates (Device Configurations)
- Administrative Template Assignments
- App Protection Policies
- Client App Assignments
- Device Compliance Policies
- Device Compliance Policy Assignments
- Device Configurations
- Device Configuration Assignments
- Device Management Scripts (Device Configuration -> PowerShell Scripts)
- Device Management Script Assignments
- Software Update Rings
- Software Update Ring Assignments
- Endpoint Security Configurations
  - Security Baselines
    - Windows 10 Security Baselines
    - Microsoft Defender ATP Baselines
    - Microsoft Edge Baseline
  - Antivirus
  - Disk encryption
  - Firewall
  - Endpoint detection and response
  - Attack surface reduction
  - Account protection
  - Device compliance

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

### Example 06 - Backup Only Intune Endpoint Security Configurations
```powershell
Invoke-IntuneBackupDeviceManagementIntent -Path C:\temp\IntuneBackup
```

### Example 07 - Restore Only Intune Endpoint Security Configurations
```powershell
Invoke-IntuneRestoreDeviceManagementIntent -Path C:\temp\IntuneBackup
```

### Example 08 - Compare two Backup Files for changes
```powershell
# The DifferenceFilePath should point to the latest Intune Backup file, as it might contain new properties.
Compare-IntuneBackupFile -ReferenceFilePath 'C:\temp\IntuneBackup\Device Configurations\Windows - Endpoint Protection.json' -DifferenceFilePath 'C:\temp\IntuneBackupLatest\Device Configurations\Windows - Endpoint Protection.json'
```

### Example 09 - Compare all files in two Backup Directories for changes
```powershell
# The DifferenceFilePath should point to the latest Intune Backup file, as it might contain new properties.
Compare-IntuneBackupDirectories -ReferenceDirectory 'C:\temp\IntuneBackup' -DifferenceDirectory 'C:\temp\IntuneBackup2'
```

## Known Issues
- Does not support backing up Intune configuration items with duplicate Display Names. Files may be overwritten.
