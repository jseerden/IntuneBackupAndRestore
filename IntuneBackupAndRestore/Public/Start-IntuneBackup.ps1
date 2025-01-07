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
        connect-mggraph -scopes "EntitlementManagement.ReadWrite.All, DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }else{
        Write-Host "MS-Graph already connected, checking scopes"
        $scopes = Get-MgContext | Select-Object -ExpandProperty Scopes
        $IncorrectScopes = $false
        if ($scopes -notcontains "DeviceManagementApps.ReadWrite.All") {$IncorrectScopes = $true}
        if ($scopes -notcontains "DeviceManagementConfiguration.ReadWrite.All") {$IncorrectScopes = $true}
        if ($scopes -notcontains "DeviceManagementServiceConfig.ReadWrite.All") {$IncorrectScopes = $true}
        if ($scopes -notcontains "DeviceManagementManagedDevices.ReadWrite.All") {$IncorrectScopes = $true}
        if ($IncorrectScopes) {
            Write-Host "Incorrect scopes, please sign in again"
            connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All"
        }else{
            Write-Host "MS-Graph scopes are correct"
        }
		Write-Host ""
    }

    Invoke-IntuneBackupAutopilotDeploymentProfile -Path $Path
    Invoke-IntuneBackupAutopilotDeploymentProfileAssignment -Path $Path
    Invoke-IntuneBackupClientApp -Path $Path
    Invoke-IntuneBackupClientAppAssignment -Path $Path
    Invoke-IntuneBackupConfigurationPolicy -Path $Path
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path $Path
    Invoke-IntuneBackupDeviceCompliancePolicy -Path $Path
    Invoke-IntuneBackupDeviceCompliancePolicyAssignment -Path $Path
    Invoke-IntuneBackupDeviceConfiguration -Path $Path
    Invoke-IntuneBackupDeviceConfigurationAssignment -Path $Path
    Invoke-IntuneBackupDeviceHealthScript -Path $Path
    Invoke-IntuneBackupDeviceHealthScriptAssignment -Path $Path
    Invoke-IntuneBackupDeviceManagementScript -Path $Path
    Invoke-IntuneBackupDeviceManagementScriptAssignment -Path $Path
    Invoke-IntuneBackupGroupPolicyConfiguration -Path $Path
    Invoke-IntuneBackupGroupPolicyConfigurationAssignment -Path $Path
    Invoke-IntuneBackupDeviceManagementIntent -Path $Path
    Invoke-IntuneBackupAppProtectionPolicy -Path $Path
    Invoke-IntuneBackupDeviceHealthScript -Path $Path
    Invoke-IntuneBackupDeviceHealthScriptAssignment -Path $Path
}
