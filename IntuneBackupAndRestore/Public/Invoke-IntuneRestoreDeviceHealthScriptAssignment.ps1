function Invoke-IntuneRestoreDeviceHealthScriptAssignment {
    <#
    .SYNOPSIS
    Restore Intune Health Script (remediation Scripts) Assignments
    
    .DESCRIPTION
    Restore Intune Health Script (remediation Scripts) Assignments from JSON files per Health Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceHealthScriptAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Health Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Health Scripts that match the file name.
    This is necessary if the Device Health Script was restored from backup, because then a new Device Health Script is created with a new unique ID.
    
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

    # Get all policies with assignments
    $deviceHealthScripts = Get-ChildItem -Path "$Path\Device Health Scripts\Assignments" -File -ErrorAction SilentlyContinue
	
    foreach ($deviceHealthScript in $deviceHealthScripts) {
        $deviceHealthScriptAssignments = Get-Content -LiteralPath $deviceHealthScript.FullName | ConvertFrom-Json
        $deviceHealthScriptId = ($deviceHealthScriptAssignments[0]).id.Split(":")[0]

        # Create the base requestBody
        $requestBody = @{
            deviceHealthScriptAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceHealthScriptAssignment in $deviceHealthScriptAssignments) {
            $requestBody.deviceHealthScriptAssignments += @{
                "target" = $deviceHealthScriptAssignment.target
				"runSchedule" = $deviceHealthScriptAssignment.runSchedule
				"runRemediationScript" = $deviceHealthScriptAssignment.runRemediationScript
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Device Health Script we are restoring the assignments for
        try {
            if ($restoreById) {
                $deviceHealthScriptObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$deviceHealthScriptId"
            }
            else {
                $deviceHealthScriptObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts" | Get-MGGraphAllPages | Where-Object displayName -eq "$($deviceHealthScript.BaseName)"
                if (-not ($deviceHealthScriptObject)) {
                    Write-Verbose "Error retrieving Intune Device Health Script for $($deviceHealthScript.FullName). Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Device Health Script for $($deviceHealthScript.FullName). Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-MgGraphRequest -Method POST -body $requestBody.toString() -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$($deviceHealthScriptObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Health Script Assignments"
                "Name"   = $deviceHealthScriptObject.displayName
                "Path"   = "Device Health Scripts\Assignments\$($deviceHealthScript.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceHealthScriptObject.displayName) - Failed to restore Device Health Script Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}