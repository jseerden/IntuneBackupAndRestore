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
        [bool]$RestoreById = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Create the base requestBody
    $requestBody = @{
        deviceManagementScriptAssignments = @()
    }

    # Get all policies with assignments
    $groupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates\Assignments" -File -ErrorAction SilentlyContinue
	
    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyConfigurationAssignments = Get-Content -LiteralPath $groupPolicyConfiguration.FullName | ConvertFrom-Json
        $groupPolicyConfigurationId = ($groupPolicyConfigurationAssignments[0]).id.Split("_")[0]
        $groupPolicyConfigurationName = $groupPolicyConfiguration.BaseName

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($groupPolicyConfigurationAssignment in $groupPolicyConfigurationAssignments) {
            $requestBody.assignments += @{
                "target" = $groupPolicyConfigurationAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Group Policy Configuration we are restoring the assignments for
        try {
            if ($restoreById) {
                $groupPolicyConfigurationObject = Invoke-MgGraphRequest -Method GET -Uri "$apiVersion/deviceManagement/groupPolicyConfigurations/$groupPolicyConfigurationId"
            }
            else {
                $groupPolicyConfigurationObject = Invoke-MgGraphRequest -Method GET -Uri "$apiVersion/deviceManagement/groupPolicyConfigurations" | Get-MGGraphAllPages | Where-Object displayName -eq $groupPolicyConfigurationName
                if (-not ($groupPolicyConfigurationObject)) {
                    Write-Verbose "Error retrieving Intune Administrative Template for $groupPolicyConfigurationName. Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Administrative Template for $groupPolicyConfigurationName. Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-MgGraphRequest -body $requestBody.toString() -Method POST -Uri "$apiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Administrative Template Assignments"
                "Name"   = $groupPolicyConfigurationObject.displayName
                "Path"   = "Administrative Templates\Assignments\$groupPolicyConfigurationName"
            }
        }
        catch {
            Write-Verbose "$groupPolicyConfigurationName - Failed to restore Administrative Template Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}