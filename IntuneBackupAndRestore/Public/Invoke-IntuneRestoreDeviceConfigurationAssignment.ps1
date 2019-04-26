function Invoke-IntuneRestoreDeviceConfigurationAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Device Configuration Assignments from JSON files per Device Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceConfigurationAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceConfigurationAssignment -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false
    )

    # Get all policies with assignments
    $deviceConfigurations = Get-ChildItem -Path "$Path\Device Configurations\Assignments"
    foreach ($deviceConfiguration in $deviceConfigurations) {
        $deviceConfigurationAssignments = Get-Content -LiteralPath $deviceConfiguration.FullName | ConvertFrom-Json
        $deviceConfigurationId = ($deviceConfigurationAssignments[0]).id.Split("_")[0]

        # Create the base requestBody
        $requestBody = @{
            deviceConfigurationGroupAssignments = @()
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceConfigurationAssignment in $deviceConfigurationAssignments) {
            $deviceConfigurationAssignmentId = ($deviceConfigurationAssignments[0]).id.Split("_")[1]

            # If group assignment
            if ($deviceConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
                $requestBody.deviceConfigurationGroupAssignments += @{
                    "@odata.type" = "#microsoft.graph.deviceConfigurationGroupAssignment"
                    targetGroupId = $deviceConfigurationAssignment.target.groupId
                }
            }

            # If exclusion group assignment
            if ($deviceConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.exclusionGroupAssignmentTarget") {
                $requestBody.deviceConfigurationGroupAssignments += @{
                    "@odata.type" = "#microsoft.graph.deviceConfigurationGroupAssignment"
                    targetGroupId = $deviceConfigurationAssignment.target.groupId
                    excludeGroup = $true
                }
            } 

            #  If 'All users' assignment 
            if ($deviceConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {
                $deviceConfigurationAssignmentId = ($deviceConfigurationAssignments[0]).id.Split("_")[1]

                $requestBody.assignments += @{
                    "@odata.type" = "#microsoft.graph.deviceConfigurationAssignment"
                    id = $deviceConfigurationAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                    }
                }
            }

            #  If 'All Devices' assignment 
            if ($deviceConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.allDevicesAssignmentTarget") {
                $deviceConfigurationAssignmentId = ($deviceConfigurationAssignments[0]).id.Split("_")[1]

                $requestBody.assignments += @{
                    "@odata.type" = "#microsoft.graph.deviceConfigurationAssignment"
                    id = $deviceConfigurationAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                    }
                }
            }
        }

        # Filter empty keys from HashTable, because mixing group and all users/devices assignments don't play along very well.
        if (-not ($requestBody.assignments)) {
            $requestBody.Remove('assignments')
        }
        elseif (-not ($requestBody.deviceConfigurationGroupAssignments)) {
            $requestBody.Remove('deviceConfigurationGroupAssignments')
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 3

        # Get the Device Configuration we are restoring the assignments for
        try {
            if ($RestoreById) {
                $deviceConfigurationObject = Get-GraphDeviceConfiguration -Id $deviceConfigurationId
            }
            else {
                $deviceConfigurationObject = Get-GraphDeviceConfiguration | Where-Object displayName -eq "$($deviceConfiguration.BaseName)"
                if (-not ($deviceConfigurationObject)) {
                    Write-Warning "Error retrieving Intune Device Configuration for $($deviceConfiguration.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error retrieving Intune Device Configuration for $($deviceConfiguration.FullName). Skipping assignment restore"
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = New-GraphDeviceConfigurationAssignment -Id $deviceConfigurationObject.id -RequestBody $requestBody -ErrorAction Stop
            Write-Output "$($deviceConfigurationObject.displayName) - Successfully restored Device Configuration Assignment(s)"
        }
        catch {
            Write-Output "$($deviceConfigurationObject.displayName) - Failed to restore Device Configuration Assignment(s)"
            Write-Error $_ -ErrorAction Continue
        }
    }
}