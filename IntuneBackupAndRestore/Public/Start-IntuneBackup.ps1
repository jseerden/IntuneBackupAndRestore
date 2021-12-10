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
    Requires the MSGraphFunctions PowerShell Module

    Connect to MSGraph first, using the 'Connect-Graph' cmdlet.
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

    Invoke-IntuneBackupClientApp -Path $Path
    Invoke-IntuneBackupClientAppAssignment -Path $Path
    Invoke-IntuneBackupConfigurationPolicy -Path $Path
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path $Path
    Invoke-IntuneBackupDeviceCompliancePolicy -Path $Path
    Invoke-IntuneBackupDeviceCompliancePolicyAssignment -Path $Path
    Invoke-IntuneBackupDeviceConfiguration -Path $Path
    Invoke-IntuneBackupDeviceConfigurationAssignment -Path $Path
    Invoke-IntuneBackupDeviceManagementScript -Path $Path
    Invoke-IntuneBackupDeviceManagementScriptAssignment -Path $Path
    Invoke-IntuneBackupGroupPolicyConfiguration -Path $Path
    Invoke-IntuneBackupGroupPolicyConfigurationAssignment -Path $Path
    Invoke-IntuneBackupDeviceManagementIntent -Path $Path
    Invoke-IntuneBackupAppProtectionPolicy -Path $Path
    Invoke-IntuneBackupDeviceHealthScript -Path $Path
    Invoke-IntuneBackupDeviceHealthScriptAssignment -Path $Path
}
