# Intune Backup & Restore

![PowerShell Gallery](https://img.shields.io/powershellgallery/v/IntuneBackupAndRestore.svg?label=PSGallery%20Version&logo=PowerShell&style=flat-square)
![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/IntuneBackupAndRestore.svg?label=PSGallery%20Downloads&logo=PowerShell&style=flat-square)

This PowerShell Module queries Microsoft Graph, and allows for cross-tenant Backup & Restore actions of your Intune Configuration.

Intune Configuration is backed up as (json) files in a given directory.

## Credits
Thanks https://github.com/mhu4711 for updating this PowerShell module to the Microsoft.Graph PowerShell module.

## Installing IntuneBackupAndRestore

```powershell
# Install IntuneBackupAndRestore from the PowerShell Gallery
Install-Module -Name IntuneBackupAndRestore
```

## Updating IntuneBackupAndRestore

```powershell
# Update IntuneBackupAndRestore from the PowerShell Gallery
Update-Module -Name IntuneBackupAndRestore
```

## Prerequisites

### Required PowerShell Modules
- [Microsoft.Graph](https://github.com/microsoftgraph/msgraph-sdk-powershell) PowerShell Module
  ```powershell
  Install-Module -Name Microsoft.Graph
  Install-Module -Name Microsoft.Graph.Beta -AllowClobber
  ```
- Make sure to import the IntuneBackupAndRestore PowerShell module before using it:
  ```powershell
  Import-Module IntuneBackupAndRestore
  ```

### Required Permissions

**For Interactive Use (Delegated Permissions):**
When running backups and restores interactively, connect with the following Microsoft Graph API scopes:

```powershell
Connect-MgGraph -Scopes @(
    'DeviceManagementApps.ReadWrite.All',
    'DeviceManagementConfiguration.ReadWrite.All',
    'DeviceManagementServiceConfig.ReadWrite.All',
    'DeviceManagementManagedDevices.ReadWrite.All',
    'DeviceManagementRBAC.ReadWrite.All',
    'DeviceManagementScripts.ReadWrite.All',
    'Policy.Read.All',
    'Policy.ReadWrite.ConditionalAccess'
)
```

**Permission Requirements by Feature:**
- **Core Intune Policies:** `DeviceManagementConfiguration.ReadWrite.All`
- **App Management:** `DeviceManagementApps.ReadWrite.All`
- **Service Configuration:** `DeviceManagementServiceConfig.ReadWrite.All`
- **Device Management:** `DeviceManagementManagedDevices.ReadWrite.All`
- **RBAC (Roles, Scope Tags):** `DeviceManagementRBAC.ReadWrite.All`
- **Scripts & Remediations:** `DeviceManagementScripts.ReadWrite.All`
- **Conditional Access (Read):** `Policy.Read.All`
- **Conditional Access (Write):** `Policy.ReadWrite.ConditionalAccess`

**For Application/Service Principal Use:**
If running backups via automation or service principals, ensure your Azure AD App Registration has these Application permissions:
- `DeviceManagementApps.ReadWrite.All`
- `DeviceManagementConfiguration.ReadWrite.All`
- `DeviceManagementServiceConfig.ReadWrite.All`
- `DeviceManagementManagedDevices.ReadWrite.All`
- `DeviceManagementRBAC.ReadWrite.All`
- `DeviceManagementScripts.ReadWrite.All`
- `Policy.Read.All`
- `Policy.ReadWrite.ConditionalAccess`

### Intune Administrator Role
The account or service principal used must have at least **Intune Administrator** role assigned in Entra ID (Azure AD).

## Features

### Backup actions
**Device Enrollment & Configuration:**
- Device Enrollment Configurations (Enrollment Restrictions, ESP)
- Autopilot Deployment Profiles
- Autopilot Deployment Profile Assignments
- Device Configurations
- Device Configuration Assignments
- Administrative Templates (Group Policy)
- Administrative Template Assignments
- Settings Catalog Policies
- Settings Catalog Policy Assignments

**Compliance & Security:**
- Device Compliance Policies
- Device Compliance Policy Assignments
- Conditional Access Policies
- Named Locations (for Conditional Access)
- Endpoint Security Configurations
  - Security Baselines (Windows 10, Defender ATP, Edge)
  - Antivirus, Disk Encryption, Firewall
  - Endpoint Detection & Response
  - Attack Surface Reduction, Account Protection
- Device Management Intent Assignments

**Applications & App Management:**
- Client Apps
- Client App Assignments
- App Protection Policies
- App Protection Policy Assignments
- Mobile App Configurations (iOS/Android device-level)
- Targeted Managed App Configurations (app-level MAM)
- Policy Sets (grouped policies)

**Windows Updates:**
- Windows Feature Update Profiles
- Windows Quality Update Profiles
- Windows Driver Update Profiles
- Software Update Rings
- Software Update Ring Assignments

**Scripts & Remediations:**
- Device Management Scripts (PowerShell Scripts)
- Device Management Script Assignments
- Proactive Remediations (Device Health Scripts)
- Proactive Remediation Assignments

**Administrative & Branding:**
- Assignment Filters
- Role Scope Tags
- Role Definitions (Custom RBAC roles)
- Notification Templates
- Terms and Conditions
- Intune Branding Profiles

### Restore actions
All policy types listed above can be restored, with the following notes:
- **Intelligent Restore:** Built-in/default objects that cannot be created are automatically skipped
- **Two-Step Process:** Configurations are restored first, then assignments
- **Cross-Tenant Support:** Policy IDs are automatically updated when restoring to different tenants
- **Policy Sets:** Container is restored; items must be re-added (due to ID changes)

> Please note that some Client App settings can be backed up, for instance the retrieval of Win32 (un)install cmdlets, requirements, etcetera. The Client App itself is not backed up and this module does not support restoring Client Apps at this time.

## Examples

### Example 01 - Full Intune Backup

**Quick Start:**
```powershell
# Connect to Microsoft Graph with all required permissions
Connect-MgGraph -Scopes @(
    'DeviceManagementApps.ReadWrite.All',
    'DeviceManagementConfiguration.ReadWrite.All',
    'DeviceManagementServiceConfig.ReadWrite.All',
    'DeviceManagementManagedDevices.ReadWrite.All',
    'DeviceManagementRBAC.ReadWrite.All',
    'DeviceManagementScripts.ReadWrite.All',
    'Policy.Read.All',
    'Policy.ReadWrite.ConditionalAccess'
)

# Run full backup
Start-IntuneBackup -Path C:\temp\IntuneBackup
```

**What gets backed up:**
- 30+ policy types including device configs, compliance, enrollment, updates, apps, and security policies
- All assignments for each configuration
- RBAC settings (scope tags, role definitions, assignment filters)
- Conditional Access policies and named locations
- Files are saved as JSON in organized folders by policy type

**Error Handling:**
The backup process now continues even if some policy types fail due to missing permissions. You'll see warnings for any skipped policy types.

### Example 02 - Full Intune Restore

**Two-Step Restore Process:**
```powershell
# Step 1: Restore all configurations (creates new policies with new IDs)
Start-IntuneRestoreConfig -Path C:\temp\IntuneBackup

# Step 2: Restore all assignments to the newly created policies
Start-IntuneRestoreAssignments -Path C:\temp\IntuneBackup
```

**Why two steps?**
Separating configuration restore from assignment restore allows you to:
1. Review restored configurations before applying assignments
2. Restore configurations to a different tenant without assignments
3. Restore only assignments if configurations already exist

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
Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path C:\temp\IntuneBackup
```

### Example 05 - Restore Only Intune Device Configurations
```powershell
Invoke-IntuneRestoreDeviceConfiguration -Path C:\temp\IntuneBackup
```

```powershell
Invoke-IntuneRestoreDeviceConfigurationAssignment -Path C:\temp\IntuneBackup
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

### Cross-Tenant Migration
This module is ideal for:
- **Tenant-to-Tenant Migrations:** Migrate configurations between Microsoft 365 tenants
- **Multi-Tenant Management:** Maintain consistent configurations across multiple tenants
- **Testing Environments:** Clone production configurations to test/dev tenants

## Performance Notes

- **Backup Time:** Depends on the number of policies (typical: 5-15 minutes for 1000+ policies)
- **Restore Time:** Slower than backup due to API rate limits (typical: 15-30 minutes for 1000+ policies)
- **Storage:** JSON files are human-readable and average 2-10 KB per policy

## Known Issues
- Does not support backing up Intune configuration items with duplicate Display Names. Files may be overwritten.
- Client Apps are backed up for reference but cannot be restored (app binaries/packages are not included)
- Some encrypted OMA settings in Device Configurations may require special permissions to decrypt during backup

## Version History

### Version 5.1.0 (2025-12-05)
- **Fixed Policy Set backup** to handle API limitation where $expand is not supported on collection queries
- **Fixed Device Enrollment Configuration restore** to use Beta API, include deviceEnrollmentConfigurationType, handle priority conflicts with auto-increment, and cast priority values to [int]
- **Fixed Notification Template restore** with two-step process (create template, then add localized messages) and proper property handling
- **Fixed Conditional Access and Named Location restore** to use Beta API and require Policy.ReadWrite.ConditionalAccess scope
- **Updated scope validation** in Start-IntuneBackup and Start-IntuneRestoreConfig to include all 8 required scopes
- **Enhanced verbose logging** throughout restore functions for better debugging
- **Improved error handling** to continue operations when individual policy types fail

### Version 5.0.0 (2025-12-01)
- **Added 17 new backup policy types:** Assignment Filters, Role Scope Tags, Device Enrollment Configurations, Named Locations, Conditional Access, Windows Update Profiles, App Configurations, Notification Templates, Branding, Terms & Conditions, Role Definitions, Policy Sets, and more
- **Added 15 new restore functions** for all new backup types
- **Enhanced error handling:** Backup/restore now continues even if individual policy types fail
- **Improved resilience:** Graceful handling of permission errors and API conflicts
- **Updated permissions:** Added RBAC and Policy scopes for new features

### Version 4.0.0 (2025-01-07)
- Complete migration to Microsoft.Graph PowerShell SDK (from deprecated MSGraph module)
- Updated all API calls to use modern Graph SDK cmdlets
- Improved error handling and resilience

## Additional Resources

- [Microsoft Graph API for Intune](https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview)
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Intune Documentation](https://learn.microsoft.com/en-us/mem/intune/)
