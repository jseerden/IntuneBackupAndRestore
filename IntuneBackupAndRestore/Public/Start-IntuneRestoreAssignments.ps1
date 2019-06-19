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
    Requires the MSGraphFunctions PowerShell Module

    Connect to MSGraph first, using the 'Connect-Graph' cmdlet.

    Set $RestoreById to $true, if the Configuration itself was not restored from backup. Set $RestoreById to $false if the configurations have been re-created (new unique ID's).
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false
    )

    Invoke-IntuneRestoreClientAppAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceConfigurationAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreDeviceManagementScriptAssignment -Path $path -RestoreById $restoreById
    Invoke-IntuneRestoreGroupPolicyConfigurationAssignment -Path $path -RestoreById $restoreById
}