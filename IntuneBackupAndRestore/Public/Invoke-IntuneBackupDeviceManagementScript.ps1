function Invoke-IntuneBackupDeviceManagementScript {
    <#
    .SYNOPSIS
    Backup Intune Device Management Scripts
    
    .DESCRIPTION
    Backup Intune Device Management Scripts as JSON files per Device Management Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceManagementScript -Path "C:\temp"
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
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all device management scripts
    $deviceManagementScripts = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceManagementScripts" | Get-MgGraphAllPages
	
	if ($deviceManagementScripts.value -ne "") {
		
	    # Create folder if not exists
		if (-not (Test-Path "$Path\Device Management Scripts\Script Content")) {
			$null = New-Item -Path "$Path\Device Management Scripts\Script Content" -ItemType Directory
		}
	
		foreach ($deviceManagementScript in $deviceManagementScripts) {
			# ScriptContent returns null, so we have to query Microsoft Graph for each script
			$deviceManagementScriptObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceManagementScripts/$($deviceManagementScript.Id)" | Get-MgGraphAllPages
			$deviceManagementScriptFileName = ($deviceManagementScriptObject.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$deviceManagementScriptObject | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Scripts\$deviceManagementScriptFileName.json"

			$deviceManagementScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($deviceManagementScriptObject.scriptContent))
			$deviceManagementScriptContent | Out-File -LiteralPath "$path\Device Management Scripts\Script Content\$deviceManagementScriptFileName.ps1"

			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Device Management Script"
				"Name"   = $deviceManagementScript.displayName
				"Path"   = "Device Management Scripts\$deviceManagementScriptFileName.json"
			}
		}
	}
}