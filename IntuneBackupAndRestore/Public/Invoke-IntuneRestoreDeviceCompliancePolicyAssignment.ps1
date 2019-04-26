function Invoke-IntuneRestoreDeviceCompliancePolicyAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Compliance Policy Assignments
    
    .DESCRIPTION
    Restore Intune Device Compliance Policy Assignments from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceCompliancePolicyAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceCompliancePolicyAssignment -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false
    )

    # Get all policies with assignments
    $deviceCompliancePolicies = Get-ChildItem -Path "$Path\Device Compliance Policies\Assignments"
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $deviceCompliancePolicyAssignments = Get-Content -LiteralPath $deviceCompliancePolicy.FullName | ConvertFrom-Json
        $deviceCompliancePolicyId = ($deviceCompliancePolicyAssignments[0]).id.Split("_")[0]

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceCompliancePolicyAssignment in $deviceCompliancePolicyAssignments) {
            $deviceCompliancePolicyAssignmentId = ($deviceCompliancePolicyAssignments[0]).id.Split("_")[1]

            # If group assignment
            if ($deviceCompliancePolicyAssignment.target."@odata.type" -eq "#microsoft.graph.groupAssignmentTarget") {
                $requestBody.assignments += @{
                    target = @{
                        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
                        groupId = $deviceCompliancePolicyAssignment.target.groupId
                    }
                }
            }

            # If exclusion group assignment
            if ($deviceCompliancePolicyAssignment.target."@odata.type" -eq "#microsoft.graph.exclusionGroupAssignmentTarget") {
                $requestBody.assignments += @{
                    target = @{
                        "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget"
                        groupId = $deviceCompliancePolicyAssignment.target.groupId
                    }
                }
            } 

            #  If 'All users' assignment 
            if ($deviceCompliancePolicyAssignment.target."@odata.type" -eq "#microsoft.graph.allLicensedUsersAssignmentTarget") {
                $deviceCompliancePolicyAssignmentId = ($deviceCompliancePolicyAssignments[0]).id.Split("_")[1]

                $requestBody.assignments += @{
                    "@odata.type" = "#microsoft.graph.deviceCompliancePolicyAssignment"
                    id = $deviceCompliancePolicyAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget"
                    }
                }
            }

            #  If 'All Devices' assignment 
            if ($deviceCompliancePolicyAssignment.target."@odata.type" -eq "#microsoft.graph.allDevicesAssignmentTarget") {
                $deviceCompliancePolicyAssignmentId = ($deviceCompliancePolicyAssignments[0]).id.Split("_")[1]

                $requestBody.assignments += @{
                    "@odata.type" = "#microsoft.graph.deviceCompliancePolicyAssignment"
                    id = $deviceCompliancePolicyAssignmentId
                    target = @{
                        "@odata.type" = "#microsoft.graph.allDevicesAssignmentTarget"
                    }
                }
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 3

        # Get the Device Compliance Policy we are restoring the assignments for
        try {
            if ($RestoreById) {
                $deviceCompliancePolicyObject = Get-GraphDeviceCompliancePolicy -Id $deviceCompliancePolicyId
            }
            else {
                $deviceCompliancePolicyObject = Get-GraphDeviceCompliancePolicy | Where-Object displayName -eq "$($deviceCompliancePolicy.BaseName)"
                if (-not ($deviceCompliancePolicyObject)) {
                    Write-Warning "Error retrieving Intune Compliance Policy for $($deviceCompliancePolicy.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error retrieving Intune Device Compliance Policy for $($deviceCompliancePolicy.FullName). Skipping assignment restore"
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = New-GraphDeviceCompliancePolicyAssignment -Id $deviceCompliancePolicyObject.id -RequestBody $requestBody -ErrorAction Stop
            Write-Output "$($deviceCompliancePolicyObject.displayName) - Successfully restored Device Compliance Policy Assignment(s)"
        }
        catch {
            Write-Output "$($deviceCompliancePolicyObject.displayName) - Failed to restore Device Compliance Policy Assignment(s)"
            Write-Error $_ -ErrorAction Continue
        }
    }
}