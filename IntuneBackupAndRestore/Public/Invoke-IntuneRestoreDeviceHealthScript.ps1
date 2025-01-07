function Invoke-IntuneRestoreDeviceHealthScript {
    <#
    .SYNOPSIS
    Restore Intune Device Health Scripts
    
    .DESCRIPTION
    Restore Intune Device Health Scripts from JSON files per Device Helth Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceHealthScript function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceHealthScript -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if($null -eq (Get-MgContext)){
        Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all device health scripts
    $deviceHealthScripts = Get-ChildItem -Path "$Path\Device Health Scripts" -File -ErrorAction SilentlyContinue
	
    foreach ($deviceHealthScript in $deviceHealthScripts) {
        $deviceHealthScriptContent = Get-Content -LiteralPath $deviceHealthScript.FullName -Raw
        $deviceHealthScriptDisplayName = ($deviceHealthScriptContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceHealthScriptContent | ConvertFrom-Json
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the device health script (excluding Microsoft builtin scripts)
		if (-not ($requestBodyObject.publisher -eq "Microsoft")) {
			try {
				$null = Invoke-MgGraphRequest -Method POST -body $requestBody.toString() -Uri "$ApiVersion/deviceManagement/deviceHealthScripts" -ErrorAction Stop
				[PSCustomObject]@{
					"Action" = "Restore"
					"Type"   = "Device Health Script"
					"Name"   = $deviceHealthScriptDisplayName
					"Path"   = "Device Health Scripts\$($deviceHealthScript.Name)"
				}
			}
			catch {
				Write-Verbose "$deviceHealthScriptDisplayName - Failed to restore Device Health Script" -Verbose
				Write-Error $_ -ErrorAction Continue
			}
		} else {
			Write-Verbose "$deviceHealthScriptDisplayName - skipped (Microsoft builtin script)" -Verbose
		}
    }
}