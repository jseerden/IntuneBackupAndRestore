function Invoke-IntuneBackupDeviceConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Device Configuration Assignments as JSON files per Device Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceConfigurationAssignment -Path "C:\temp"
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

    # Get all assignments from all policies
    $deviceConfigurations = Invoke-MgGraphRequest -Uri "$apiVersion/deviceManagement/deviceConfigurations" | Get-MGGraphAllPages

	if ($deviceConfigurations -and $deviceConfigurations.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Configurations\Assignments")) {
			$null = New-Item -Path "$Path\Device Configurations\Assignments" -ItemType Directory
		}
	
		foreach ($deviceConfiguration in $deviceConfigurations) {
			$assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceConfigurations/$($deviceConfiguration.id)/assignments" | Get-MGGraphAllPages
	
			if ($assignments) {
				$fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
				$assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Configurations\Assignments\$fileName.json"
	
				[PSCustomObject]@{
					"Action" = "Backup"
					"Type"   = "Device Configuration Assignments"
					"Name"   = $deviceConfiguration.displayName
					"Path"   = "Device Configurations\Assignments\$fileName.json"
				}
			}
		}
	}
}
