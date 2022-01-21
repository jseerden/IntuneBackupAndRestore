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

    [PSCustomObject]@{
        "Action" = "Restore"
        "Type"   = "Intune Backup and Restore Action"
        "Name"   = "IntuneBackupAndRestore - Start Intune Restore Config"
        "Path"   = $Path
    }

    Invoke-IntuneRestoreConfigurationPolicy -Path $Path -RestoreById $RestoreById
    Invoke-IntuneRestoreDeviceCompliancePolicy -Path $Path -RestoreById $RestoreById
    Invoke-IntuneRestoreDeviceConfiguration -Path $Path -RestoreById $RestoreById
    Invoke-IntuneRestoreDeviceManagementScript -Path $Path -RestoreById $RestoreById
    Invoke-IntuneRestoreGroupPolicyConfiguration -Path $Path -RestoreById $RestoreById
    Invoke-IntuneRestoreDeviceManagementIntent -Path $Path -RestoreById $RestoreById
    Invoke-IntuneRestoreAppProtectionPolicy -Path $Path -RestoreById $RestoreById
}
