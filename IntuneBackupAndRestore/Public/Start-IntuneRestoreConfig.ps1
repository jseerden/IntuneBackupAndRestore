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
  
    }

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
