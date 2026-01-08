function Invoke-IntuneRestoreDeviceEnrollmentConfiguration {
    <#
    .SYNOPSIS
    Restore Intune Device Enrollment Configurations

    .DESCRIPTION
    Restore Intune Device Enrollment Configurations (Enrollment Restrictions and Enrollment Status Page profiles) from JSON files from the specified Path.
    Handles priority conflicts by automatically finding the next available priority value.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceEnrollmentConfiguration function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreDeviceEnrollmentConfiguration -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get existing enrollment configurations to check for priority conflicts
    try {
        $existingConfigurations = Invoke-MgGraphRequest -Method GET -Uri "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations" -ErrorAction Stop
        $existingPriorities = @()
        if ($existingConfigurations.value) {
            $existingPriorities = $existingConfigurations.value | Where-Object { $_.priority -ne $null } | Select-Object -ExpandProperty priority
        }
        Write-Verbose "Found $($existingPriorities.Count) existing enrollment configurations with priorities" -Verbose
    }
    catch {
        Write-Warning "Could not retrieve existing enrollment configurations. Priority conflicts may occur."
        $existingPriorities = @()
    }

    # Get all Device Enrollment Configurations
    $enrollmentConfigurations = Get-ChildItem -Path "$Path\Device Enrollment Configurations" -File -ErrorAction SilentlyContinue

    foreach ($enrollmentConfiguration in $enrollmentConfigurations) {
        $enrollmentConfigurationContent = Get-Content -LiteralPath $enrollmentConfiguration.FullName -Raw | ConvertFrom-Json

        $enrollmentConfigurationDisplayName = $enrollmentConfigurationContent.displayName

        # Skip default/global enrollment restrictions and unsupported types (these cannot be created, only modified)
        $unsupportedTypes = @(
            "#microsoft.graph.windowsRestoreDeviceEnrollmentConfiguration"  # Windows Restore config - built-in only
        )

        if ($enrollmentConfigurationDisplayName -like "Global-*" -or
            $enrollmentConfigurationDisplayName -eq "All users and all devices" -or
            $enrollmentConfigurationContent.'@odata.type' -in $unsupportedTypes) {
            Write-Verbose "Skipping built-in Device Enrollment Configuration: $enrollmentConfigurationDisplayName" -Verbose
            continue
        }

        # Remove properties that are not available for creating a new enrollment configuration
        $requestBody = $enrollmentConfigurationContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, modifiedDateTime, supportsScopeTags

        # Handle priority conflicts - find next available priority if the current one is taken
        if ($requestBody.priority -ne $null) {
            $originalPriority = [int]$requestBody.priority
            if ($existingPriorities -contains $originalPriority) {
                # Priority conflict detected - find next available priority
                $maxPriority = [int]($existingPriorities | Measure-Object -Maximum).Maximum
                $newPriority = [int]($maxPriority + 1)

                Write-Verbose "$enrollmentConfigurationDisplayName - Priority conflict detected (priority $originalPriority already exists). Using priority $newPriority instead." -Verbose
                $requestBody.priority = $newPriority

                # Add the new priority to the tracking list
                $existingPriorities += $newPriority
            }
            else {
                Write-Verbose "$enrollmentConfigurationDisplayName - Using original priority: $originalPriority" -Verbose
                # Add this priority to the tracking list
                $existingPriorities += $originalPriority
            }
        }

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Debug: Log the request body
        Write-Verbose "REQUEST BODY FOR $enrollmentConfigurationDisplayName :" -Verbose
        Write-Verbose $requestBodyJson -Verbose

        # Restore the Device Enrollment Configuration
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Enrollment Configuration"
                "Name"   = $enrollmentConfigurationDisplayName
                "Path"   = "Device Enrollment Configurations\$($enrollmentConfiguration.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$enrollmentConfigurationDisplayName - Failed to restore Device Enrollment Configuration" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
