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
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all device management scripts
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts" -File -ErrorAction SilentlyContinue
	
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptContent = Get-Content -LiteralPath $deviceManagementScript.FullName | Convertfrom-Json

        $deviceManagementScriptDisplayName = $deviceManagementScriptContent.displayName  
        
        # Remove properties that are not available for creating a new configuration
        $requestBody = $deviceManagementScriptContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the device management script
        try {
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$apiVersion/deviceManagement/deviceManagementScripts" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Script"
                "Name"   = $deviceManagementScriptDisplayName
                "Path"   = "Device Management Scripts\$($deviceManagementScript.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceManagementScriptDisplayName - Failed to restore Device Management Script" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}