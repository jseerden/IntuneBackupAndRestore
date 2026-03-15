function Start-IntuneRestoreAssignments() {
    <#
    .SYNOPSIS
    Restore Intune Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Configuration Assignments
    
    .PARAMETER Path
    Path where backup (JSON) files are located.
    
    .EXAMPLE
    Start-IntuneRestoreAssignments -Path C:\temp -RestoreById $false
    
    .NOTES
    Requires the MSGraph SDK PowerShell Module

    Connect to MSGraph first, using the 'Connect-MgGraph' cmdlet.

    Set $RestoreById to $true, if the Configuration itself was not restored from backup. Set $RestoreById to $false if the configurations have been re-created (new unique ID's).
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false
    )

    [PSCustomObject]@{
        "Action" = "Restore"
        "Type"   = "Intune Backup and Restore Action"
        "Name"   = "IntuneBackupAndRestore - Start Intune Restore Assignments"
        "Path"   = $Path
    }

    #Connect to MS-Graph if required
    $requiredScopes = @(
        "DeviceManagementApps.ReadWrite.All"
        "DeviceManagementConfiguration.ReadWrite.All"
        "DeviceManagementServiceConfig.ReadWrite.All"
        "DeviceManagementScripts.ReadWrite.All"
    )
    Test-GraphConnection -RequiredScopes $requiredScopes -CheckScopes

    Invoke-IntuneRestoreAutopilotDeploymentProfileAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreConfigurationPolicyAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreClientAppAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceConfigurationAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceHealthScriptAssignment -Path $Path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceManagementScriptAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreGroupPolicyConfigurationAssignment -Path $path -RestoreById $restoreById
	
}