function Invoke-IntuneRestoreConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Restore Intune Configuration Policy Assignments
    
    .DESCRIPTION
    Restore Intune Configuration Policy Assignments from JSON files per Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupConfigurationPolicyAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to true, assignments will be restored to Intune Device Management Scripts that match the id.

    If RestoreById is set to false, assignments will be restored to Intune Device Management Scripts that match the file name.
    This is necessary if the Device Management Script was restored from backup, because then a new Device Management Script is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path "C:\temp" -RestoreById $true
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
    if($null -eq (Get-MgContext)){
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all policies with assignments
    $configurationPolicies = Get-ChildItem -Path "$Path\Settings Catalog\Assignments" -File -ErrorAction SilentlyContinue
	
    foreach ($configurationPolicy in $configurationPolicies) {
        $configurationPolicyAssignments = Get-Content -LiteralPath $configurationPolicy.FullName | ConvertFrom-Json
        $configurationPolicyId = ($configurationPolicyAssignments[0]).id.Split("_")[0]
        $configurationPolicyName = $configurationPolicy.BaseName
		
        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($configurationPolicyAssignment in $configurationPolicyAssignments) {
            $requestBody.assignments += @{
                "target" = $configurationPolicyAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Configuration Policy we are restoring the assignments for
        try {
            if ($restoreById) {
                $configurationPolicyObject = Invoke-MgGraphRequest -method GET -Uri "$apiVersion/deviceManagement/configurationPolicies/$configurationPolicyId"
            }
            else {
                $configurationPolicyObject =  Invoke-MgGraphRequest -method GET -Uri "$apiVersion/deviceManagement/configurationPolicies" | Get-MgGraphAllPages | Where-Object name -eq $configurationPolicyName 
                if (-not ($configurationPolicyObject)) {
                    Write-Verbose "Error retrieving Intune Session Catalog for $($configurationPolicy.FullName). Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Session Catalog for $($configurationPolicy.FullName). Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-MgGraphRequest -method POST -body $requestBody.toString() -Uri "$apiVersion/deviceManagement/configurationPolicies/$($configurationPolicyObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Settings Catalog Assignments"
                "Name"   = $configurationPolicyObject.name
                "Path"   = "Settings Catalog\Assignments\$($configurationPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$($configurationPolicyObject.name) - Failed to restore Settings Catalog Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}