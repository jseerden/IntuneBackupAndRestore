function Invoke-IntuneRestoreAutopilotDeploymentProfileAssignment {
    <#
    .SYNOPSIS
    Restore Intune Autopilot Deployment Profile Assignments
    
    .DESCRIPTION
    Restore Intune Autopilot Deployment Profile Assignments from JSON files per profile from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAutopilotDeploymentProfileAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Autopilot Deployment Profiles that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Autopilot Deployment Profiles that match the file name.
    This is necessary if the Autopilot Deployment Profile was restored from backup, because then a new Autopilot Deployment Profile is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceHealthScriptAssignment -Path "C:\temp" -RestoreById $true
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

    # Get all profiles with assignments
    $winAutopilotDeploymentProfiles = Get-ChildItem -Path "$Path\Autopilot Deployment Profiles\Assignments" -File -ErrorAction SilentlyContinue
	
    foreach ($winAutopilotDeploymentProfile in $winAutopilotDeploymentProfiles) {
        $winAutopilotDeploymentProfileAssignments = Get-Content -LiteralPath $winAutopilotDeploymentProfile.FullName | ConvertFrom-Json
        $winAutopilotDeploymentProfileId = ($winAutopilotDeploymentProfileAssignments[0]).id.Split(":")[0]

        # Create the base requestBody
        $requestBody = @{
            winAutopilotDeploymentProfileAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($winAutopilotDeploymentProfileAssignment in $winAutopilotDeploymentProfileAssignments) {
            $requestBody.winAutopilotDeploymentProfileAssignments += @{
                "target" = $winAutopilotDeploymentProfileAssignment.target
				"source" = $winAutopilotDeploymentProfileAssignment.source
				"sourceId" = $winAutopilotDeploymentProfileAssignment.sourceId
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Autopilot Deployment Profile we are restoring the assignments for
        try {
            if ($restoreById) {
                $winAutopilotDeploymentProfileObject = Invoke-MgGraphRequest -Uri "deviceManagement/windowsAutopilotDeploymentProfiles/$winAutopilotDeploymentProfileId"
            }
            else {
                $winAutopilotDeploymentProfileObject = Invoke-MgGraphRequest -Uri "deviceManagement/windowsAutopilotDeploymentProfiles" | Get-MGGraphAllPages | Where-Object displayName -eq "$($winAutopilotDeploymentProfile.BaseName)"
                if (-not ($winAutopilotDeploymentProfileObject)) {
                    Write-Verbose "Error retrieving Intune Autopilot Deployment Profile for $($winAutopilotDeploymentProfile.FullName). Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Autopilot Deployment Profile for $($winAutopilotDeploymentProfile.FullName). Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
			# FIXME: look into why POSTing to this Graph API endpoint currently results in error "403 Forbidden - FeatureNotEnabled",
            # although the user account has the required permissions as documented in https://docs.microsoft.com/en-us/graph/api/intune-shared-windowsautopilotdeploymentprofile-assign?view=graph-rest-beta
            $null = Invoke-MgGraphRequest -Method POST -Content $requestBody.toString() -Uri "deviceManagement/windowsAutopilotDeploymentProfiles/$($winAutopilotDeploymentProfileObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Autopilot Deployment Profile Assignments"
                "Name"   = $winAutopilotDeploymentProfileObject.displayName
                "Path"   = "Autopilot Deployment Profiles\Assignments\$($winAutopilotDeploymentProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$($winAutopilotDeploymentObject.displayName) - Failed to restore Autopilot Deployment Profile Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}