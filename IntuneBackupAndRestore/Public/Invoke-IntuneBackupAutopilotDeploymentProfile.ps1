﻿function Invoke-IntuneBackupAutopilotDeploymentProfile {
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

    # Create folder if not exists
    if (-not (Test-Path "$Path\Autopilot Deployment Profiles")) {
        $null = New-Item -Path "$Path\Autopilot Deployment Profiles" -ItemType Directory
    }

    $winAutopilotDeploymentProfiles = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles" | Select-Object -ExpandProperty Value

    foreach ($winAutopilotDeploymentProfile in $winAutopilotDeploymentProfiles) {
        $fileName = ($winAutopilotDeploymentProfile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        # Export the Deployment profile
		$winAutopilotDeploymentProfileObject = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($winAutopilotDeploymentProfile.id)"
		$winAutopilotDeploymentProfileObject | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Autopilot Deployment Profiles\$fileName.json"

		[PSCustomObject]@{
			"Action" = "Backup"
			"Type"   = "Autopilot Deployment Profile"
			"Name"   = $winAutopilotDeploymentProfileObject.displayName
			"Path"   = "Autopilot Deployment Profiles\$fileName.json"
		}
	
    }
}
