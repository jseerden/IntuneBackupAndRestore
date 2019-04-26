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
        [bool]$RestoreById = $false
    )

    # Get all policies with assignments
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts\Assignments"
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptAssignments = Get-Content -LiteralPath $deviceManagementScript.FullName | ConvertFrom-Json
        $deviceManagementScriptId = ($deviceManagementScriptAssignments[0]).id.Split(":")[0]

        # Create the base requestBody
        $requestBody = @{
            deviceManagementScriptGroupAssignments = @()
            deviceManagementScriptAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceManagementScriptAssignment in $deviceManagementScriptAssignments) {
            $deviceManagementScriptAssignmentId = ($deviceManagementScriptAssignments[0]).id.Split(":")[1]
            # If group assignment
            if ($deviceManagementScriptAssignment.target."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
                $requestBody.deviceManagementScriptGroupAssignments += @{
                    "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
                    targetGroupId = $deviceManagementScriptAssignment.target.groupId
                }
            }

            # If exclusion group assignment
            if ($deviceManagementScriptAssignment.target."@odata.type" -eq "#microsoft.graph.exclusionGroupAssignmentTarget") {
                $requestBody.deviceManagementScriptGroupAssignments += @{
                    "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
                    targetGroupId = $deviceManagementScriptAssignment.target.groupId
                    excludeGroup = $true
                }
            } 

            #  If 'All users' assignment 
            if ($deviceManagementScriptAssignment.target."@odata.type" -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {

                $requestBody.deviceManagementScriptAssignments += @{
                    "@odata.type" = "#microsoft.graph.deviceManagementScriptAssignment"
                    id = $deviceManagementScriptAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                    }
                }
            }

            #  If 'All Devices' assignment 
            if ($deviceManagementScriptAssignment.target."@odata.type" -eq "#microsoft.graph.allDevicesAssignmentTarget") {

                $requestBody.deviceManagementScriptAssignments += @{
                    "@odata.type" = "#microsoft.graph.deviceManagementScriptAssignment"
                    id = $deviceManagementScriptAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                    }
                }
            }
        }

        # Filter empty keys from HashTable, because mixing group and all users/devices assignments don't play along very well.
        if (-not ($requestBody.deviceManagementScriptAssignments)) {
            $requestBody.Remove('deviceManagementScriptAssignments')
        }
        elseif (-not ($requestBody.deviceManagementScriptGroupAssignments)) {
            $requestBody.Remove('deviceManagementScriptGroupAssignments')
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 3

        # Get the Device Management Script we are restoring the assignments for
        try {
            if ($RestoreById) {
                $deviceManagementScriptObject = Get-GraphDeviceManagementScript -Id $deviceManagementScriptId
            }
            else {
                $deviceManagementScriptObject = Get-GraphDeviceManagementScript | Where-Object displayName -eq "$($deviceManagementScript.BaseName)"
                if (-not ($deviceManagementScriptObject)) {
                    Write-Warning "Error retrieving Intune Device Management Script for $($deviceManagementScript.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error retrieving Intune Device Management Script for $($deviceManagementScript.FullName). Skipping assignment restore"
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = New-GraphDeviceManagementScriptAssignment -Id $deviceManagementScriptObject.id -RequestBody $requestBody -ErrorAction Stop
            Write-Output "$($deviceManagementScriptObject.displayName) - Successfully restored Device Management Script Assignment(s)"
        }
        catch {
            Write-Output "$($deviceManagementScriptObject.displayName) - Failed to restore Device Management Script Assignment(s)"
            Write-Error $_ -ErrorAction Continue
        }
    }
}