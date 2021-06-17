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
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Configurations")) {
        $null = New-Item -Path "$Path\Device Configurations" -ItemType Directory
    }

    # Get all device configurations
    $deviceConfigurations = Get-DeviceManagement_DeviceConfigurations | Get-MSGraphAllPages

    foreach ($deviceConfiguration in $deviceConfigurations) {
        $fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $deviceConfiguration | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Configurations\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Configuration"
            "Name"   = $deviceConfiguration.displayName
            "Path"   = "Device Configurations\$fileName.json"
        }
    }
}