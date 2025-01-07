function Invoke-IntuneRestoreAutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Restore Intune Autopilot Deployment Profiles
    
    .DESCRIPTION
    Restore Intune Autopilot Deployment Profiles from JSON files per Deployment Profile from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAutopilotDeploymentProfile function
    
    .EXAMPLE
    Invoke-IntuneRestoreAutopilotDeploymentProfile -Path "C:\temp"
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
    $winAutopilotDeploymentProfiles = Get-ChildItem -Path "$Path\Autopilot Deployment Profiles" -File -ErrorAction SilentlyContinue
	
    foreach ($winAutopilotDeploymentProfile in $winAutopilotDeploymentProfiles) {
        $winAutopilotDeploymentProfileContent = Get-Content -LiteralPath $winAutopilotDeploymentProfile.FullName -Raw
        $winAutopilotDeploymentProfileDisplayName = ($winAutopilotDeploymentProfileContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new profile
        $requestBodyObject = $winAutopilotDeploymentProfileContent | ConvertFrom-Json
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the Deployment Profile
		try {
			$null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles" -ErrorAction Stop
			[PSCustomObject]@{
				"Action" = "Restore"
				"Type"   = "Autopilot Deployment Profile"
				"Name"   = $winAutopilotDeploymentProfileDisplayName
				"Path"   = "Autopilot Deployment Profiles\$($winAutopilotDeploymentProfile.Name)"
			}
		}
		catch {
			Write-Verbose "$winAutopilotDeploymentProfile - Failed to restore Autopilot Deployment Profile" -Verbose
			Write-Error $_ -ErrorAction Continue
		}
    }
}