function Invoke-IntuneBackupDeviceConfiguration {
    <#
    .SYNOPSIS
    Backup Intune Device Configurations
    
    .DESCRIPTION
    Backup Intune Device Configurations as JSON files per Device Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceConfiguration -Path "C:\temp"
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

    # Get all device configurations
    $deviceConfigurations = Invoke-MgGraphRequest -Uri "$apiVersion/deviceManagement/deviceConfigurations" | Get-MGGraphAllPages

	if ($deviceConfigurations -and $deviceConfigurations.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Configurations")) {
			$null = New-Item -Path "$Path\Device Configurations" -ItemType Directory
		}
	
		foreach ($deviceConfiguration in $deviceConfigurations) {
			$fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
	
			# If it's a custom configuration, check if the device configuration contains encrypted OMA settings, then decrypt the OmaSettings to a Plain Text Value (required for import)
			if (($deviceConfiguration.'@odata.type' -eq '#microsoft.graph.windows10CustomConfiguration') -and ($deviceConfiguration.omaSettings | Where-Object { $_.isEncrypted -contains $true } )) {
				# Create an empty array for the unencrypted OMA settings.
				$newOmaSettings = @()
				foreach ($omaSetting in $deviceConfiguration.omaSettings) {
					# Check if this particular setting is encrypted, and get the plaintext only if necessary
					if ($omaSetting.isEncrypted) {
						$omaSettingValue = Invoke-MgGraphRequest -Uri "$apiVersion/deviceManagement/deviceConfigurations/$($deviceConfiguration.id)/getOmaSettingPlainTextValue(secretReferenceValueId='$($omaSetting.secretReferenceValueId)')" | Get-MgGraphAllPages
					} else {
						$omaSettingValue = $omaSetting.value
					}
					# Define a new 'unencrypted' OMA Setting
					$newOmaSetting = @{}
					$newOmaSetting.'@odata.type' = $omaSetting.'@odata.type'
					$newOmaSetting.displayName = $omaSetting.displayName
					$newOmaSetting.description = $omaSetting.description
					$newOmaSetting.omaUri = $omaSetting.omaUri
					$newOmaSetting.value = $omaSettingValue
					$newOmaSetting.isEncrypted = $false
					$newOmaSetting.secretReferenceValueId = $null
	
					# Add the unencrypted OMA Setting to the Array
					$newOmaSettings += $newOmaSetting
				}
	
				# Remove all encrypted OMA Settings from the Device Configuration
				$deviceConfiguration.omaSettings = @()
	
				# Add the unencrypted OMA Settings from the Device Configuration
				$deviceConfiguration.omaSettings += $newOmaSettings
			}
	
			# Export the Device Configuration Profile
			$deviceConfiguration | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Configurations\$fileName.json"
	
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Device Configuration"
				"Name"   = $deviceConfiguration.displayName
				"Path"   = "Device Configurations\$fileName.json"
			}
		}
	}
}
