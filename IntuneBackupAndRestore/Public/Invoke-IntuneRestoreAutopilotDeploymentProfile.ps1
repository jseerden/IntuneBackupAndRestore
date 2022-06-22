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

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all device health scripts
    $winAutopilotDeploymentProfiles = Get-ChildItem -Path "$Path\Autopilot Deployment Profiles" -File
    foreach ($winAutopilotDeploymentProfile in $winAutopilotDeploymentProfiles) {
        $winAutopilotDeploymentProfileContent = Get-Content -LiteralPath $winAutopilotDeploymentProfile.FullName -Raw
        $winAutopilotDeploymentProfileDisplayName = ($winAutopilotDeploymentProfileContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new profile
        $requestBodyObject = $winAutopilotDeploymentProfileContent | ConvertFrom-Json
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the Deployment Profile
		try {
			$null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/windowsAutopilotDeploymentProfiles" -ErrorAction Stop
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