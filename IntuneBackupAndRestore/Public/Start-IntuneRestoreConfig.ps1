function Start-IntuneRestoreConfig() {
    <#
    .SYNOPSIS
    Restore Intune Configuration
    
    .DESCRIPTION
    Restore Intune Configuration
    
    .PARAMETER Path
    Path where backup (JSON) files are located.
    
    .EXAMPLE
    Start-IntuneRestore -Path C:\temp
    
    .NOTES
    Requires the MSGraph SDK PowerShell Module

    Connect to MSGraph first, using the 'Connect-MgGraph' cmdlet.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    [PSCustomObject]@{
        "Action" = "Restore"
        "Type"   = "Intune Backup and Restore Action"
        "Name"   = "IntuneBackupAndRestore - Start Intune Restore Config"
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
            throw "Insufficient permissions. Restore cannot continue."
        }else{
            Write-Host "MS-Graph scopes are correct"
        }

    }

    # Restore dependencies first (needed by other policies)
    try { Invoke-IntuneRestoreRoleScopeTag -Path $Path } catch { Write-Warning "Failed to restore Role Scope Tags: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreAssignmentFilter -Path $Path } catch { Write-Warning "Failed to restore Assignment Filters: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreNamedLocation -Path $Path } catch { Write-Warning "Failed to restore Named Locations: $($_.Exception.Message)" }

    # Restore enrollment configurations
    try { Invoke-IntuneRestoreDeviceEnrollmentConfiguration -Path $Path } catch { Write-Warning "Failed to restore Device Enrollment Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreAutopilotDeploymentProfile -Path $Path } catch { Write-Warning "Failed to restore Autopilot Deployment Profiles: $($_.Exception.Message)" }

    # Restore device configurations
    try { Invoke-IntuneRestoreConfigurationPolicy -Path $Path } catch { Write-Warning "Failed to restore Configuration Policies: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreDeviceConfiguration -Path $Path } catch { Write-Warning "Failed to restore Device Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreGroupPolicyConfiguration -Path $Path } catch { Write-Warning "Failed to restore Group Policy Configurations: $($_.Exception.Message)" }

    # Restore compliance policies
    try { Invoke-IntuneRestoreDeviceCompliancePolicy -Path $Path } catch { Write-Warning "Failed to restore Device Compliance Policies: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreDeviceManagementIntent -Path $Path } catch { Write-Warning "Failed to restore Device Management Intents: $($_.Exception.Message)" }

    # Restore Windows Update profiles
    try { Invoke-IntuneRestoreWindowsFeatureUpdateProfile -Path $Path } catch { Write-Warning "Failed to restore Windows Feature Update Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreWindowsQualityUpdateProfile -Path $Path } catch { Write-Warning "Failed to restore Windows Quality Update Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreWindowsDriverUpdateProfile -Path $Path } catch { Write-Warning "Failed to restore Windows Driver Update Profiles: $($_.Exception.Message)" }

    # Restore applications and app configurations
    try { Invoke-IntuneRestoreAppProtectionPolicy -Path $Path } catch { Write-Warning "Failed to restore App Protection Policies: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreMobileAppConfiguration -Path $Path } catch { Write-Warning "Failed to restore Mobile App Configurations: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreTargetedManagedAppConfiguration -Path $Path } catch { Write-Warning "Failed to restore Targeted Managed App Configurations: $($_.Exception.Message)" }

    # Restore scripts
    try { Invoke-IntuneRestoreDeviceHealthScript -Path $Path } catch { Write-Warning "Failed to restore Device Health Scripts: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreDeviceManagementScript -Path $Path } catch { Write-Warning "Failed to restore Device Management Scripts: $($_.Exception.Message)" }

    # Restore Conditional Access
    try { Invoke-IntuneRestoreConditionalAccessPolicy -Path $Path } catch { Write-Warning "Failed to restore Conditional Access Policies: $($_.Exception.Message)" }

    # Restore administrative and branding
    try { Invoke-IntuneRestoreRoleDefinition -Path $Path } catch { Write-Warning "Failed to restore Role Definitions: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreNotificationTemplate -Path $Path } catch { Write-Warning "Failed to restore Notification Templates: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreTermsAndConditions -Path $Path } catch { Write-Warning "Failed to restore Terms and Conditions: $($_.Exception.Message)" }
    try { Invoke-IntuneRestoreIntuneBrandingProfile -Path $Path } catch { Write-Warning "Failed to restore Intune Branding Profiles: $($_.Exception.Message)" }
    try { Invoke-IntuneRestorePolicySet -Path $Path } catch { Write-Warning "Failed to restore Policy Sets: $($_.Exception.Message)" }
}
