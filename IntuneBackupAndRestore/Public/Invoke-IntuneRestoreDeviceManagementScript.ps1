function Invoke-IntuneRestoreDeviceManagementScript {
    <#
    .SYNOPSIS
    Restore Intune Device Management Scripts
    
    .DESCRIPTION
    Restore Intune Device Management Scripts from JSON files per Device Management Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementScript function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceManagementScript -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Get all device management scripts
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts" -File
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptContent = Get-Content -LiteralPath $deviceManagementScript.FullName -Raw
        $deviceManagementScriptDisplayName = ($deviceManagementScriptContent | ConvertFrom-Json).displayName        

        # Restore the device management script
        try {
            $null = New-GraphDeviceManagementScript -RequestBody $deviceManagementScriptContent -ErrorAction Stop
            Write-Output "$deviceManagementScriptDisplayName - Successfully restored Device Management Script"
        }
        catch {
            Write-Output "$deviceManagementScriptDisplayName - Failed to restore Device Management Script"
            Write-Error $_ -ErrorAction Continue
        }
    }
}