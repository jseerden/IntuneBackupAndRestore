function Invoke-IntuneBackupDeviceConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Device Configuration Assignments as JSON files per Device Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceConfigurationAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Configurations\Assignments")) {
        $null = New-Item -Path "$Path\Device Configurations\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $deviceConfigurations = Get-GraphDeviceConfiguration

    foreach ($deviceConfiguration in $deviceConfigurations) {
        $assignments = Get-GraphDeviceConfigurationAssignment -Id $deviceConfiguration.id 
        if ($assignments) {
            Write-Output "Backing Up - Device Configuration - Assignments: $($deviceConfiguration.displayName)"
            $fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Configurations\Assignments\$fileName.json"
        }
    }
}