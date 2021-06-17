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
        [bool]$RestoreById = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all policies with assignments
    $deviceConfigurations = Get-ChildItem -Path "$Path\Device Configurations\Assignments"
    foreach ($deviceConfiguration in $deviceConfigurations) {
        $deviceConfigurationAssignments = Get-Content -LiteralPath $deviceConfiguration.FullName | ConvertFrom-Json

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceConfigurationAssignment in $deviceConfigurationAssignments) {
            $requestBody.assignments += @{
                "target" = $deviceConfigurationAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Device Configuration we are restoring the assignments for
        try {
            if ($restoreById) {
                $deviceConfigurationObject = Get-DeviceManagement_DeviceConfigurations -DeviceConfigurationId $deviceConfigurationAssignments[0].deviceConfigurationId
            }
            else {
                $deviceConfigurationObject = Get-DeviceManagement_DeviceConfigurations | Get-MSGraphAllPages | Where-Object displayName -eq "$($deviceConfiguration.BaseName)"
                if (-not ($deviceConfigurationObject)) {
                    Write-Verbose "Error retrieving Intune Device Configuration for $($deviceConfiguration.FullName). Skipping assignment restore" -Verbose
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Device Configuration for $($deviceConfiguration.FullName). Skipping assignment restore" -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/deviceConfigurations/$($deviceConfigurationObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Configuration Assignments"
                "Name"   = $deviceConfigurationObject.displayName
                "Path"   = "Device Configurations\Assignments\$($deviceConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceConfigurationObject.displayName) - Failed to restore Device Configuration Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}