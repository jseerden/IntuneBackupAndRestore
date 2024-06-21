function Invoke-IntuneRestoreDeviceConfiguration {
    <#
    .SYNOPSIS
    Restore Intune Device Configurations
    
    .DESCRIPTION
    Restore Intune Device Configurations from JSON files per Device Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceConfigurations function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceConfiguration -Path "C:\temp" -RestoreById $true
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
    if($null -eq (Get-MgContext)){
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all device configurations
    $deviceConfigurations = Get-ChildItem -Path "$path\Device Configurations" -File -ErrorAction SilentlyContinue
    
    foreach ($deviceConfiguration in $deviceConfigurations) {
        $deviceConfigurationContent = Get-Content -LiteralPath $deviceConfiguration.FullName -Raw | ConvertFrom-Json

        $deviceConfigurationDisplayName = $deviceConfigurationContent.displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceConfigurationContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version
        # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
        if ($requestBodyObject.supportsScopeTags) {
            $requestBodyObject.supportsScopeTags = $false
        }

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject  | ConvertTo-Json -Depth 100

        # Restore the device configuration
        try {
            $null = Invoke-MgGraphRequest -Method POST -body $requestBody.toString() -Uri "$ApiVersion/deviceManagement/deviceConfigurations" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Configuration"
                "Name"   = $deviceConfigurationDisplayName
                "Path"   = "Device Configurations\$($deviceConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceConfigurationDisplayName - Failed to restore Device Configuration" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}