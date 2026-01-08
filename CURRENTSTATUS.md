# IntuneBackupAndRestore - Current Development Status

**Last Updated:** 2025-12-05
**Current Version:** 5.1.0
**Status:** Configuration Restore Complete ✅ | Assignment Restore Pending 🔄

---

## Overview

This document tracks the current implementation status of all policy types in the IntuneBackupAndRestore module, including implementation details, known issues, and next steps.

## Implementation Status Summary

| Category | Backup | Restore | Assignments | Status |
|----------|--------|---------|-------------|--------|
| **Core Configuration** | ✅ Complete | ✅ Complete | 🔄 Pending | Ready for Assignment Work |
| **Enrollment & Autopilot** | ✅ Complete | ✅ Complete | 🔄 Pending | Ready for Assignment Work |
| **Security & Compliance** | ✅ Complete | ✅ Complete | 🔄 Pending | Ready for Assignment Work |
| **Windows Updates** | ✅ Complete | ✅ Complete | 🔄 Pending | Ready for Assignment Work |
| **Apps & MAM** | ✅ Complete | ✅ Complete | 🔄 Pending | Ready for Assignment Work |
| **Administrative** | ✅ Complete | ✅ Complete | N/A | Assignment Filters, Scope Tags, Roles don't have assignments |

---

## Policy Types - Detailed Status

### 1. Assignment Filters
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupAssignmentFilter` ✅
- `Invoke-IntuneRestoreAssignmentFilter` ✅

**API Details:**
- Endpoint: `v1.0/deviceManagement/assignmentFilters`
- Permissions: `DeviceManagementConfiguration.ReadWrite.All`

**Implementation Notes:**
- No special handling required
- Assignment Filters themselves don't have assignments

**Next Steps:**
- None - Complete

---

### 2. Role Scope Tags
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupRoleScopeTag` ✅
- `Invoke-IntuneRestoreRoleScopeTag` ✅

**API Details:**
- Endpoint: `Beta/deviceManagement/roleScopeTags`
- Permissions: `DeviceManagementRBAC.ReadWrite.All`

**Implementation Notes:**
- Skips built-in scope tag (id = "0")
- Uses Beta API endpoint

**Next Steps:**
- None - Complete (Scope Tags don't have assignments)

---

### 3. Device Enrollment Configurations
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupDeviceEnrollmentConfiguration` ✅
- `Invoke-IntuneRestoreDeviceEnrollmentConfiguration` ✅

**API Details:**
- Endpoint: `Beta/deviceManagement/deviceEnrollmentConfigurations`
- Permissions: `DeviceManagementServiceConfig.ReadWrite.All`
- **IMPORTANT:** Must use Beta API (v1.0 not supported)

**Implementation Notes:**
- **Priority Conflict Resolution:** Automatically increments priority if conflict detected
- **Required Properties:** Must include `deviceEnrollmentConfigurationType` in restore
- **Type Casting:** Priority values must be cast to [int] to prevent type conversion errors
- **Skipped Types:** Skips `windowsRestoreDeviceEnrollmentConfiguration` (built-in only)
- **Skipped Policies:** Skips "Global-*" and "All users and all devices" (built-in)

**Nuances:**
```powershell
# Priority handling example
$originalPriority = [int]$requestBody.priority
if ($existingPriorities -contains $originalPriority) {
    $maxPriority = [int]($existingPriorities | Measure-Object -Maximum).Maximum
    $newPriority = [int]($maxPriority + 1)
    $requestBody.priority = $newPriority
}
```

**Known Issues:**
- None - Fully functional

**Next Steps:**
- ❌ No assignment restore needed (enrollment configs use priority-based targeting)

---

### 4. Named Locations
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupNamedLocation` ✅
- `Invoke-IntuneRestoreNamedLocation` ✅

**API Details:**
- Endpoint: `Beta/identity/conditionalAccess/namedLocations`
- Permissions: `Policy.ReadWrite.ConditionalAccess`
- **IMPORTANT:** Must use Beta API

**Implementation Notes:**
- Used by Conditional Access policies
- Supports both IP-based and country-based locations

**Next Steps:**
- ❌ No assignment restore needed (Referenced by Conditional Access policies)

---

### 5. Conditional Access Policies
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupConditionalAccessPolicy` ✅
- `Invoke-IntuneRestoreConditionalAccessPolicy` ✅

**API Details:**
- Endpoint: `Beta/identity/conditionalAccess/policies`
- Permissions: `Policy.ReadWrite.ConditionalAccess`
- **IMPORTANT:** Must use Beta API

**Implementation Notes:**
- Skips built-in policies (e.g., "Default Policy")
- Contains user/group assignments directly in policy definition

**Next Steps:**
- ❌ No assignment restore needed (assignments embedded in policy)

---

### 6. Windows Feature Update Profiles
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupWindowsFeatureUpdateProfile` ✅
- `Invoke-IntuneRestoreWindowsFeatureUpdateProfile` ✅
- `Invoke-IntuneRestoreWindowsFeatureUpdateProfileAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceManagement/windowsFeatureUpdateProfiles`
- Permissions: `DeviceManagementConfiguration.ReadWrite.All`

**Next Steps:**
- 🔄 Create assignment restore function

---

### 7. Windows Quality Update Profiles
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupWindowsQualityUpdateProfile` ✅
- `Invoke-IntuneRestoreWindowsQualityUpdateProfile` ✅
- `Invoke-IntuneRestoreWindowsQualityUpdateProfileAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceManagement/windowsQualityUpdateProfiles`
- Permissions: `DeviceManagementConfiguration.ReadWrite.All`

**Next Steps:**
- 🔄 Create assignment restore function

---

### 8. Windows Driver Update Profiles
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupWindowsDriverUpdateProfile` ✅
- `Invoke-IntuneRestoreWindowsDriverUpdateProfile` ✅
- `Invoke-IntuneRestoreWindowsDriverUpdateProfileAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceManagement/windowsDriverUpdateProfiles`
- Permissions: `DeviceManagementConfiguration.ReadWrite.All`

**Next Steps:**
- 🔄 Create assignment restore function

---

### 9. Mobile App Configurations
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupMobileAppConfiguration` ✅
- `Invoke-IntuneRestoreMobileAppConfiguration` ✅
- `Invoke-IntuneRestoreMobileAppConfigurationAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceAppManagement/mobileAppConfigurations`
- Permissions: `DeviceManagementApps.ReadWrite.All`

**Implementation Notes:**
- Used for iOS/Android managed device configurations
- Different from Targeted MAM configurations

**Next Steps:**
- 🔄 Create assignment restore function

---

### 10. Targeted Managed App Configurations
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupTargetedManagedAppConfiguration` ✅
- `Invoke-IntuneRestoreTargetedManagedAppConfiguration` ✅
- `Invoke-IntuneRestoreTargetedManagedAppConfigurationAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceAppManagement/targetedManagedAppConfigurations`
- Permissions: `DeviceManagementApps.ReadWrite.All`

**Implementation Notes:**
- Used for app-level MAM configurations (without enrollment)
- Different from Mobile App Configurations (device-level)

**Next Steps:**
- 🔄 Create assignment restore function

---

### 11. Notification Templates
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupNotificationTemplate` ✅
- `Invoke-IntuneRestoreNotificationTemplate` ✅

**API Details:**
- Endpoint: `v1.0/deviceManagement/notificationMessageTemplates`
- Permissions: `DeviceManagementServiceConfig.ReadWrite.All`

**Implementation Notes:**
- **Two-Step Restore Process:**
  1. Create notification template (without localized messages)
  2. Add localized messages via separate POST to sub-resource
- **Property Handling:**
  - Remove `defaultLocale` during creation (causes BadRequest)
  - Remove `description` during creation (causes BadRequest)
  - Keep `brandingOptions` as comma-separated string (e.g., "includeCompanyLogo,includeCompanyName,includeContactInformation")
- **Display Name Limit:** Maximum 50 characters (automatically truncated if longer)

**Nuances:**
```powershell
# Step 1: Create template without localized messages
$requestBody = $notificationTemplateContent | Select-Object -Property * -ExcludeProperty `
    id, createdDateTime, lastModifiedDateTime, modifiedDateTime, supportsScopeTags, `
    'localizedNotificationMessages@odata.context', localizedNotificationMessages

# Remove properties that cause BadRequest errors
$requestBody.PSObject.Properties.Remove('defaultLocale')
$requestBody.PSObject.Properties.Remove('description')

# Step 2: Add localized messages
foreach ($message in $localizedMessages) {
    $messageBody = $message | Select-Object -Property * -ExcludeProperty id, lastModifiedDateTime, isDefault
    $messageBody | Add-Member -MemberType NoteProperty -Name "@odata.type" `
        -Value "#microsoft.graph.localizedNotificationMessage" -Force

    Invoke-MgGraphRequest -Method POST -Body $messageBodyJson.toString() `
        -Uri "$ApiVersion/deviceManagement/notificationMessageTemplates/$($createdTemplate.id)/localizedNotificationMessages"
}
```

**Known Issues:**
- None - Fully functional

**Next Steps:**
- ❌ No assignment restore needed (used by compliance policies, not independently assigned)

---

### 12. Intune Branding Profiles
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupIntuneBrandingProfile` ✅
- `Invoke-IntuneRestoreIntuneBrandingProfile` ✅
- `Invoke-IntuneRestoreIntuneBrandingProfileAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceManagement/intuneBrandingProfiles`
- Permissions: `DeviceManagementServiceConfig.ReadWrite.All`

**Next Steps:**
- 🔄 Create assignment restore function

---

### 13. Terms and Conditions
**Status:** ✅ Backup Complete | 🔄 Restore & Assignments Pending

**Functions:**
- `Invoke-IntuneBackupTermsAndConditions` ✅
- `Invoke-IntuneRestoreTermsAndConditions` ✅
- `Invoke-IntuneRestoreTermsAndConditionsAssignment` ❌ NOT CREATED YET

**API Details:**
- Endpoint: `Beta/deviceManagement/termsAndConditions`
- Permissions: `DeviceManagementServiceConfig.ReadWrite.All`

**Next Steps:**
- 🔄 Create assignment restore function

---

### 14. Role Definitions
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupRoleDefinition` ✅
- `Invoke-IntuneRestoreRoleDefinition` ✅

**API Details:**
- Endpoint: `Beta/deviceManagement/roleDefinitions`
- Permissions: `DeviceManagementRBAC.ReadWrite.All`

**Implementation Notes:**
- Skips built-in roles (e.g., isBuiltIn = true)
- Only custom role definitions are backed up and restored

**Next Steps:**
- ❌ No assignment restore needed (roles are assigned separately via role assignments)

---

### 15. Policy Sets
**Status:** ✅ Backup Complete | 🔄 Restore Incomplete

**Functions:**
- `Invoke-IntuneBackupPolicySet` ✅
- `Invoke-IntuneRestorePolicySet` ✅

**API Details:**
- Endpoint: `Beta/deviceAppManagement/policySets`
- Permissions: `DeviceManagementApps.ReadWrite.All`

**Implementation Notes:**
- **Backup:** Uses individual item queries with $expand (collection-level $expand not supported by API)
- **Restore Limitation:** Container is restored but items cannot be automatically re-added due to ID changes across tenants
- Policy Set items must be manually re-added after cross-tenant restore

**Nuances:**
```powershell
# Cannot use $expand on collection
# BAD:  Invoke-MgGraphRequest -Uri "Beta/deviceAppManagement/policySets?`$expand=items"
# GOOD: Query each policy set individually
$policySets = Invoke-MgGraphRequest -Uri "Beta/deviceAppManagement/policySets"
foreach ($policySet in $policySets) {
    $policySetWithItems = Invoke-MgGraphRequest -Uri "Beta/deviceAppManagement/policySets/$($policySet.id)?`$expand=items"
}
```

**Known Issues:**
- Policy Set items are not restored (limitation by design due to cross-tenant ID changes)

**Next Steps:**
- 🔄 Create assignment restore function (for the Policy Set container itself)

---

### 16. Device Management Intent Assignments
**Status:** ✅ Fully Implemented

**Functions:**
- `Invoke-IntuneBackupDeviceManagementIntentAssignment` ✅

**API Details:**
- Endpoint: `Beta/deviceManagement/intents/{id}/assignments`
- Permissions: `DeviceManagementConfiguration.ReadWrite.All`

**Implementation Notes:**
- Backs up assignments for Endpoint Security configurations (Security Baselines, Antivirus, Firewall, etc.)
- Assignment restore for Device Management Intents is handled by existing functions

**Next Steps:**
- None - Already integrated

---

## Required API Permissions

### Complete List (8 Scopes)
```powershell
@(
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

### Scope Usage by Policy Type

| Scope | Policy Types |
|-------|-------------|
| `DeviceManagementApps.ReadWrite.All` | Mobile App Configs, Targeted MAM Configs, Policy Sets, Client Apps |
| `DeviceManagementConfiguration.ReadWrite.All` | Device Configs, Compliance, Settings Catalog, Windows Updates, Assignment Filters |
| `DeviceManagementServiceConfig.ReadWrite.All` | Enrollment Configs, Notification Templates, Branding, Terms & Conditions |
| `DeviceManagementManagedDevices.ReadWrite.All` | Device-level operations |
| `DeviceManagementRBAC.ReadWrite.All` | Role Definitions, Scope Tags |
| `DeviceManagementScripts.ReadWrite.All` | PowerShell Scripts, Proactive Remediations |
| `Policy.Read.All` | General policy read access |
| `Policy.ReadWrite.ConditionalAccess` | Conditional Access Policies, Named Locations |

---

## Known API Quirks and Workarounds

### 1. Beta vs v1.0 Endpoints

**Must Use Beta:**
- Device Enrollment Configurations
- Conditional Access Policies
- Named Locations
- Role Scope Tags
- Policy Sets
- Windows Update Profiles
- Mobile App Configurations
- Targeted MAM Configurations
- Branding Profiles
- Terms and Conditions
- Role Definitions
- Device Management Intents

**Can Use v1.0:**
- Notification Templates (v1.0 recommended)
- Assignment Filters

### 2. Property Exclusions During Restore

**Always Exclude:**
- `id` (system-generated)
- `createdDateTime` (system-generated)
- `lastModifiedDateTime` (system-generated)
- `modifiedDateTime` (system-generated)
- `supportsScopeTags` (read-only)

**Conditional Exclusions:**
- `version` (read-only for most types)
- `@odata.context` and other OData metadata
- `deviceEnrollmentConfigurationType` - **KEEP THIS** (required for enrollment configs)

### 3. Two-Step Restore Processes

**Notification Templates:**
1. Create template without `localizedNotificationMessages`
2. POST each localized message to sub-resource endpoint

**General Pattern for Complex Objects:**
- Create parent object first
- Add child objects via sub-resource endpoints

### 4. Priority Conflict Handling

**Device Enrollment Configurations:**
- Query existing configurations first
- If priority conflict, auto-increment to max + 1
- Cast all priority values to `[int]` to prevent type errors

---

## Testing Infrastructure

### Debug Scripts Location
`/debug/` folder contains:

1. **Connect-IntuneBackupGraph.ps1**
   - Centralized connection script
   - Supports both interactive and app registration authentication
   - Variable-based configuration (no parameters)

2. **Prepare-TestRestoreDirectory.ps1**
   - Creates test environment with subset of policies
   - Renames policies with "TSTRSTR" prefix
   - Filters out built-in/default policies
   - Configurable max policies per type (default: 3)

3. **Invoke-TestRestore.ps1**
   - Automated test restore with comprehensive logging
   - Creates timestamped log files
   - Tracks created policy IDs for cleanup
   - Generates error reports

4. **Remove-IntuneTestRestorePolicies.ps1**
   - Cleanup script for test policies
   - Reads created policy IDs from JSON
   - Removes test policies safely

### Test Workflow
```powershell
# 1. Connect to Graph
.\debug\Connect-IntuneBackupGraph.ps1

# 2. Prepare test environment
.\debug\Prepare-TestRestoreDirectory.ps1 -SourcePath "C:\Temp\12-4-25" -DestinationPath "C:\Temp\Test-Restore"

# 3. Run test restore
.\debug\Invoke-TestRestore.ps1

# 4. Clean up test policies
.\debug\Remove-IntuneTestRestorePolicies.ps1 -PolicyListPath "C:\Temp\Test-Restore\CreatedPolicies_YYYYMMDD_HHMMSS.json"
```

---

## Next Steps - Assignment Restore Development

### Priority Order for Assignment Restore Implementation

**Phase 1 - High Priority (Core Policies):**
1. Windows Feature Update Profile Assignments
2. Windows Quality Update Profile Assignments
3. Windows Driver Update Profile Assignments
4. Mobile App Configuration Assignments
5. Targeted MAM Configuration Assignments

**Phase 2 - Medium Priority (Administrative):**
6. Intune Branding Profile Assignments
7. Terms and Conditions Assignments
8. Policy Set Assignments

**Phase 3 - Documentation & Testing:**
9. Update README with assignment restore examples
10. Add comprehensive assignment tests to test scripts
11. Document any assignment-specific nuances

### Assignment Restore Template

Each assignment restore function should follow this pattern:

```powershell
function Invoke-IntuneRestore[PolicyType]Assignment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Get all policies with backed up assignments
    $policies = Get-ChildItem -Path "$Path\[Policy Folder]" -Filter "*.json"

    foreach ($policy in $policies) {
        $policyContent = Get-Content -LiteralPath $policy.FullName | ConvertFrom-Json

        # Check if assignments exist
        $assignmentPath = "$Path\[Policy Folder]\Assignments"
        if (-not (Test-Path $assignmentPath)) { continue }

        $assignmentFile = Get-ChildItem -Path $assignmentPath -Filter "$($policy.BaseName)*.json"
        if (-not $assignmentFile) { continue }

        $assignments = Get-Content -LiteralPath $assignmentFile.FullName | ConvertFrom-Json

        # Get restored policy ID (from restore output or query by displayName)
        $restoredPolicy = # Query API for policy by displayName

        foreach ($assignment in $assignments) {
            # Build assignment body
            $assignmentBody = @{
                target = $assignment.target
            }

            # POST assignment
            Invoke-MgGraphRequest -Method POST -Body ($assignmentBody | ConvertTo-Json -Depth 10) `
                -Uri "[API Endpoint]/$($restoredPolicy.id)/assignments"
        }
    }
}
```

### Assignment Restore Considerations

1. **Group ID Translation:** Assignments reference group IDs that may differ across tenants
2. **All Users/All Devices:** Special group IDs that need to be preserved
3. **Filters:** Assignment filters must exist before restoring assignments
4. **Exclusions:** Properly handle inclusion vs exclusion groups
5. **Intent vs Target:** Different policy types use different assignment structures

---

## Completed Work Summary

### Version 5.1.0 Achievements

✅ **Fixed Policy Set Backup** - API limitation with $expand workaround
✅ **Fixed Device Enrollment Configuration Restore** - Beta API, priority conflicts, type casting
✅ **Fixed Notification Template Restore** - Two-step process, property handling
✅ **Fixed Conditional Access** - Beta API and permissions
✅ **Updated Scope Validation** - All 8 required scopes
✅ **Created Testing Infrastructure** - Complete test workflow with cleanup
✅ **Enhanced Error Handling** - Continues on individual failures
✅ **Comprehensive Documentation** - CHANGELOG, README updates

### Policy Types Ready for Production

All 16 policy types listed above have **fully functional backup and restore** for the configurations themselves. Assignment restore is the remaining work item.

---

## Support and Contribution

For issues, questions, or contributions related to:
- **Backup/Restore Functions:** Open an issue on GitHub
- **Assignment Restore Development:** Refer to this document's "Next Steps" section
- **API Changes:** Check Microsoft Graph API documentation for breaking changes

**Documentation References:**
- [Microsoft Graph API for Intune](https://learn.microsoft.com/en-us/graph/api/resources/intune-graph-overview)
- [Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
