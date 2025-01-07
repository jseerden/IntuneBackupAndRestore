function Invoke-IntuneBackupAutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Backup Intune Autopilot Deployment Profiles

    .DESCRIPTION
    Backup Intune Autopilot Deployment Profiles as JSON files per deployment profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .EXAMPLE
    Invoke-IntuneBackupAutopilotDeploymentProfile -Path "C:\temp"
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
	
	# Get all Autopilot Deployment Profiles
    $winAutopilotDeploymentProfiles = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles" -OutputType PSObject | Select-Object -ExpandProperty Value

	if ($winAutopilotDeploymentProfiles.value -ne "") {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Autopilot Deployment Profiles")) {
			$null = New-Item -Path "$Path\Autopilot Deployment Profiles" -ItemType Directory
		}
	
		foreach ($winAutopilotDeploymentProfile in $winAutopilotDeploymentProfiles) {
			$fileName = ($winAutopilotDeploymentProfile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
	
			# Export the Deployment profile
			$winAutopilotDeploymentProfileObject = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($winAutopilotDeploymentProfile.id)"
			$winAutopilotDeploymentProfileObject | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Autopilot Deployment Profiles\$fileName.json"
	
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Autopilot Deployment Profile"
				"Name"   = $winAutopilotDeploymentProfileObject.displayName
				"Path"   = "Autopilot Deployment Profiles\$fileName.json"
			}
		
		}
	}
}
