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
    $requiredScopes = @(
        "DeviceManagementApps.ReadWrite.All"
        "DeviceManagementConfiguration.ReadWrite.All"
        "DeviceManagementServiceConfig.ReadWrite.All"
        "DeviceManagementScripts.ReadWrite.All"
    )
    Test-GraphConnection -RequiredScopes $requiredScopes -CheckScopes

    Invoke-IntuneRestoreAutopilotDeploymentProfile -Path $Path
    Invoke-IntuneRestoreConfigurationPolicy -Path $Path
    Invoke-IntuneRestoreDeviceCompliancePolicy -Path $Path
    Invoke-IntuneRestoreDeviceConfiguration -Path $Path
    Invoke-IntuneRestoreDeviceHealthScript -Path $Path
    Invoke-IntuneRestoreDeviceManagementScript -Path $Path
    Invoke-IntuneRestoreGroupPolicyConfiguration -Path $Path
    Invoke-IntuneRestoreDeviceManagementIntent -Path $Path
    Invoke-IntuneRestoreAppProtectionPolicy -Path $Path
}
