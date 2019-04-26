function Invoke-IntuneRestoreGroupPolicyConfigurationAssignment {
    <#
    .SYNOPSIS
    Restore Intune Group Policy Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Group Policy Configuration Assignments from JSON files per Group Policy Configuration from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupGroupPolicyConfigurationAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreGroupPolicyConfigurationAssignment -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false
    )

    # Get all policies with assignments
    $groupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates\Assignments"
    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyConfigurationAssignments = Get-Content -LiteralPath $groupPolicyConfiguration.FullName | ConvertFrom-Json
        $groupPolicyConfigurationId = ($groupPolicyConfigurationAssignments[0]).id.Split("_")[0]

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($groupPolicyConfigurationAssignment in $groupPolicyConfigurationAssignments) {
            $groupPolicyConfigurationAssignmentId = ($groupPolicyConfigurationAssignments[0]).id.Split("_")[1]

            # If group assignment
            if ($groupPolicyConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
                $requestBody.assignments += @{
                    target = @{
                        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                        groupId = $groupPolicyConfigurationAssignment.target.groupId
                    }
                }
            }

            # If exclusion group assignment
            if ($groupPolicyConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.exclusionGroupAssignmentTarget") {
                $requestBody.assignments += @{
                    target = @{
                        "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget"
                        groupId = $groupPolicyConfigurationAssignment.target.groupId
                    }
                }
            } 

            #  If 'All users' assignment 
            if ($groupPolicyConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {
                $groupPolicyConfigurationAssignmentId = ($groupPolicyConfigurationAssignments[0]).id.Split("_")[1]

                $requestBody.assignments += @{
                    "@odata.type" = "#microsoft.graph.groupPolicyConfigurationAssignment"
                    id = $groupPolicyConfigurationAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                    }
                }
            }

            #  If 'All Devices' assignment 
            if ($groupPolicyConfigurationAssignment.target."@odata.type" -eq "#microsoft.graph.allDevicesAssignmentTarget") {
                $groupPolicyConfigurationAssignmentId = ($groupPolicyConfigurationAssignments[0]).id.Split("_")[1]

                $requestBody.assignments += @{
                    "@odata.type" = "#microsoft.graph.groupPolicyConfigurationAssignment"
                    id = $groupPolicyConfigurationAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                    }
                }
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 3

        # Get the Group Policy Configuration we are restoring the assignments for
        try {
            if ($RestoreById) {
                $groupPolicyConfigurationObject = Get-GraphGroupPolicyConfiguration -Id $groupPolicyConfigurationId
            }
            else {
                $groupPolicyConfigurationObject = Get-GraphGroupPolicyConfiguration | Where-Object displayName -eq "$($groupPolicyConfiguration.BaseName)"
                if (-not ($groupPolicyConfigurationObject)) {
                    Write-Warning "Error retrieving Intune Administrative Template for $($groupPolicyConfiguration.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error retrieving Intune Administrative Template for $($groupPolicyConfiguration.FullName). Skipping assignment restore"
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = New-GraphGroupPolicyConfigurationAssignment -Id $groupPolicyConfigurationObject.id -RequestBody $requestBody -ErrorAction Stop
            Write-Output "$($groupPolicyConfigurationObject.displayName) - Successfully restored Administrative Template Assignment(s)"
        }
        catch {
            Write-Output "$($groupPolicyConfigurationObject.displayName) - Failed to restore Administrative Template Assignment(s)"
            Write-Error $_ -ErrorAction Continue
        }
    }
}