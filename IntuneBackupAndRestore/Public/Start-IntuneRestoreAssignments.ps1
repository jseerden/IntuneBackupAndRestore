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
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, DeviceManagementScripts.ReadWrite.All" 
    }else{
        Write-Host "MS-Graph already connected, checking scopes"
        $scopes = Get-MgContext | Select-Object -ExpandProperty Scopes
        $requiredScopes = @(
            "DeviceManagementApps.ReadWrite.All",
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementServiceConfig.ReadWrite.All",
            "DeviceManagementManagedDevices.ReadWrite.All"
        )
        # Use case-insensitive comparison
        $missingScopes = $requiredScopes | Where-Object {
            $requiredScope = $_
            -not ($scopes | Where-Object { $_ -eq $requiredScope })
        }

        if ($missingScopes) {
            Write-Error "Missing required permission scopes: $($missingScopes -join ', ')"
            Write-Error "Please reconnect with the correct permissions using: Connect-MgGraph -Scopes 'DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All'"
            throw "Insufficient permissions. Restore assignments cannot continue."
        }else{
            Write-Host "MS-Graph scopes are correct"
        }

    }

    Invoke-IntuneRestoreAutopilotDeploymentProfileAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreConfigurationPolicyAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreClientAppAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreDeviceConfigurationAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreDeviceHealthScriptAssignment -Path $Path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreDeviceManagementScriptAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue
    Invoke-IntuneRestoreGroupPolicyConfigurationAssignment -Path $path -RestoreById $restoreById -ErrorAction Continue

}