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
        [string]$Path
    )

    # Get all device configurations
    $deviceConfigurations = Get-ChildItem -Path "$Path\Device Configurations" -File
    foreach ($deviceConfiguration in $deviceConfigurations) {
        $deviceConfigurationContent = Get-Content -LiteralPath $deviceConfiguration.FullName -Raw
        $deviceConfigurationDisplayName = ($deviceConfigurationContent | ConvertFrom-Json).displayName

        # Restore the device configuration
        try {
            $null = New-GraphDeviceConfiguration -RequestBody $deviceConfigurationContent -ErrorAction Stop
            Write-Output "$deviceConfigurationDisplayName - Successfully restored Device Configuration"
        }
        catch {
            Write-Output "$deviceConfigurationDisplayName - Failed to restore Device Configuration"
            Write-Error $_ -ErrorAction Continue
        }
    }
}