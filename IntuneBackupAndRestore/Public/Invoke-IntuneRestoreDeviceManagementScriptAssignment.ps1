function Invoke-IntuneRestoreDeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Management Script Assignments
    
    .DESCRIPTION
    Restore Intune Device Management Script Assignments from JSON files per Device Management Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementScriptAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceManagementScriptAssignment -Path "C:\temp" -RestoreById $true
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

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all policies with assignments
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts\Assignments" -File -ErrorAction SilentlyContinue
	
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptAssignments = Get-Content -LiteralPath $deviceManagementScript.FullName | ConvertFrom-Json
        $deviceManagementScriptId = ($deviceManagementScriptAssignments[0]).id.Split(":")[0]
        $deviceManagementScriptName = $deviceManagementScript.BaseName

        # Create the base requestBody
        $requestBody = @{
            deviceManagementScriptAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceManagementScriptAssignment in $deviceManagementScriptAssignments) {
            $requestBody.deviceManagementScriptAssignments += @{
                "target" = $deviceManagementScriptAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Device Management Script we are restoring the assignments for
        try {
            if ($restoreById) {
                $deviceManagementScriptObject = Invoke-MgGraphRequest -Uri "$apiVersion/deviceManagement/deviceManagementScripts/$deviceManagementScriptId"
            }
            else {
                $deviceManagementScriptObject = Invoke-MgGraphRequest -Uri "$apiVersion/deviceManagement/deviceManagementScripts" | Get-MGGraphAllPages | Where-Object displayName -eq $deviceManagementScriptName
                if (-not ($deviceManagementScriptObject)) {
                    Write-Verbose "Error retrieving Intune Device Management Script for $deviceManagementScriptName. Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Device Management Script for $deviceManagementScriptName. Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$apiVersion/deviceManagement/deviceManagementScripts/$($deviceManagementScriptObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Script Assignments"
                "Name"   = $deviceManagementScriptObject.displayName
                "Path"   = "Device Management Scripts\Assignments\$($deviceManagementScript.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceManagementScriptName - Failed to restore Device Management Script Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}