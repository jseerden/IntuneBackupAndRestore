function Start-IntuneBackup() {
    <#
    .SYNOPSIS
    Backup Intune Configuration

    .DESCRIPTION
    Backup Intune Configuration

    .PARAMETER Path
    Path to store backup (JSON) files.

    .EXAMPLE
    Start-IntuneBackup -Path C:\temp

    .NOTES
    Requires the MSGraph SDK PowerShell Module

    Connect to MSGraph first, using the 'Connect-MgGraph' cmdlet and the scopes: 'DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All'.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "Intune Backup and Restore Action"
        "Name"   = "IntuneBackupAndRestore - Start Intune Backup Config and Assignments"
        "Path"   = $Path
    }

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementRBAC.ReadWrite.All, DeviceManagementScripts.ReadWrite.All, Policy.Read.All, Policy.ReadWrite.ConditionalAccess"
    }else{
        Write-Host "MS-Graph already connected, checking scopes"
        $scopes = Get-MgContext | Select-Object -ExpandProperty Scopes
        $requiredScopes = @(
            "DeviceManagementApps.ReadWrite.All",
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementServiceConfig.ReadWrite.All",
            "DeviceManagementManagedDevices.ReadWrite.All",
            "DeviceManagementRBAC.ReadWrite.All",
            "DeviceManagementScripts.ReadWrite.All",
            "Policy.Read.All",
            "Policy.ReadWrite.ConditionalAccess"
        )
        # Use case-insensitive comparison
        $missingScopes = $requiredScopes | Where-Object {
            $requiredScope = $_
            -not ($scopes | Where-Object { $_ -eq $requiredScope })
        }

        if ($missingScopes) {
            Write-Error "Missing required permission scopes: $($missingScopes -join ', ')"
            Write-Error "Please reconnect with the correct permissions using: Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementRBAC.ReadWrite.All, DeviceManagementScripts.ReadWrite.All, Policy.Read.All, Policy.ReadWrite.ConditionalAccess'"
            throw "Insufficient permissions. Backup cannot continue."
        }else{
            Write-Host "MS-Graph scopes are correct"
        }
		Write-Host ""
    }

    # Backup dependencies first (needed by other policies)
    try { Invoke-IntuneBackupRoleScopeTag -Path $Path } catch { Write-Warning "Failed to backup Role Scope Tags: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupAssignmentFilter -Path $Path } catch { Write-Warning "Failed to backup Assignment Filters: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupNamedLocation -Path $Path } catch { Write-Warning "Failed to backup Named Locations: $($_.Exception.Message)" }

    # Backup enrollment configurations
    try { Invoke-IntuneBackupDeviceEnrollmentConfiguration -Path $Path } catch { Write-Warning "Failed to backup Device Enrollment Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupAutopilotDeploymentProfile -Path $Path } catch { Write-Warning "Failed to backup Autopilot Deployment Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupAutopilotDeploymentProfileAssignment -Path $Path } catch { Write-Warning "Failed to backup Autopilot Deployment Profile Assignments: $($_.Exception.Message)" }

    # Backup device configurations
    try { Invoke-IntuneBackupConfigurationPolicy -Path $Path } catch { Write-Warning "Failed to backup Configuration Policies: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupConfigurationPolicyAssignment -Path $Path } catch { Write-Warning "Failed to backup Configuration Policy Assignments: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceConfiguration -Path $Path } catch { Write-Warning "Failed to backup Device Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceConfigurationAssignment -Path $Path } catch { Write-Warning "Failed to backup Device Configuration Assignments: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupGroupPolicyConfiguration -Path $Path } catch { Write-Warning "Failed to backup Group Policy Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupGroupPolicyConfigurationAssignment -Path $Path } catch { Write-Warning "Failed to backup Group Policy Configuration Assignments: $($_.Exception.Message)" }

    # Backup compliance policies
    try { Invoke-IntuneBackupDeviceCompliancePolicy -Path $Path } catch { Write-Warning "Failed to backup Device Compliance Policies: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceCompliancePolicyAssignment -Path $Path } catch { Write-Warning "Failed to backup Device Compliance Policy Assignments: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceManagementIntent -Path $Path } catch { Write-Warning "Failed to backup Device Management Intents: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceManagementIntentAssignment -Path $Path } catch { Write-Warning "Failed to backup Device Management Intent Assignments: $($_.Exception.Message)" }

    # Backup Windows Update profiles
    try { Invoke-IntuneBackupWindowsFeatureUpdateProfile -Path $Path } catch { Write-Warning "Failed to backup Windows Feature Update Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupWindowsQualityUpdateProfile -Path $Path } catch { Write-Warning "Failed to backup Windows Quality Update Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupWindowsDriverUpdateProfile -Path $Path } catch { Write-Warning "Failed to backup Windows Driver Update Profiles: $($_.Exception.Message)" }

    # Backup applications and app configurations
    try { Invoke-IntuneBackupClientApp -Path $Path } catch { Write-Warning "Failed to backup Client Apps: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupClientAppAssignment -Path $Path } catch { Write-Warning "Failed to backup Client App Assignments: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupAppProtectionPolicy -Path $Path } catch { Write-Warning "Failed to backup App Protection Policies: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupMobileAppConfiguration -Path $Path } catch { Write-Warning "Failed to backup Mobile App Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupTargetedManagedAppConfiguration -Path $Path } catch { Write-Warning "Failed to backup Targeted Managed App Configurations: $($_.Exception.Message)" }

    # Backup scripts
    try { Invoke-IntuneBackupDeviceHealthScript -Path $Path } catch { Write-Warning "Failed to backup Device Health Scripts: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceHealthScriptAssignment -Path $Path } catch { Write-Warning "Failed to backup Device Health Script Assignments: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceManagementScript -Path $Path } catch { Write-Warning "Failed to backup Device Management Scripts: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupDeviceManagementScriptAssignment -Path $Path } catch { Write-Warning "Failed to backup Device Management Script Assignments: $($_.Exception.Message)" }

    # Backup Conditional Access
    try { Invoke-IntuneBackupConditionalAccessPolicy -Path $Path } catch { Write-Warning "Failed to backup Conditional Access Policies: $($_.Exception.Message)" }

    # Backup administrative and branding
    try { Invoke-IntuneBackupRoleDefinition -Path $Path } catch { Write-Warning "Failed to backup Role Definitions: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupNotificationTemplate -Path $Path } catch { Write-Warning "Failed to backup Notification Templates: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupTermsAndConditions -Path $Path } catch { Write-Warning "Failed to backup Terms and Conditions: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupIntuneBrandingProfile -Path $Path } catch { Write-Warning "Failed to backup Intune Branding Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneBackupPolicySet -Path $Path } catch { Write-Warning "Failed to backup Policy Sets: $($_.Exception.Message)" }
}
