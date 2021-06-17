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

    Invoke-IntuneRestoreConfigurationPolicy -Path $Path
    Invoke-IntuneRestoreDeviceCompliancePolicy -Path $Path
    Invoke-IntuneRestoreDeviceConfiguration -Path $Path
    Invoke-IntuneRestoreDeviceManagementScript -Path $Path
    Invoke-IntuneRestoreGroupPolicyConfiguration -Path $Path
    Invoke-IntuneRestoreDeviceManagementIntent -Path $Path
    Invoke-IntuneRestoreAppProtectionPolicy -Path $Path
}
