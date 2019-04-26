function Invoke-IntuneBackupDeviceConfiguration {
    <#
    .SYNOPSIS
    Backup Intune Device Configurations
    
    .DESCRIPTION
    Backup Intune Device Configurations as JSON files per Device Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceConfiguration -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Configurations")) {
        $null = New-Item -Path "$Path\Device Configurations" -ItemType Directory
    }

    # Get all device configurations
    $deviceConfigurations = Get-GraphDeviceConfiguration

    foreach ($deviceConfiguration in $deviceConfigurations) {
        Write-Output "Backing Up - Device Configuration: $($deviceConfiguration.displayName)"
        $fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $deviceConfiguration | ConvertTo-Json | Out-File -LiteralPath "$path\Device Configurations\$fileName.json"
    }
}