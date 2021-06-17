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
    if (-not (Test-Path "$Path\Device Configurations\Assignments")) {
        $null = New-Item -Path "$Path\Device Configurations\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $deviceConfigurations = Get-DeviceManagement_DeviceConfigurations | Get-MSGraphAllPages

    foreach ($deviceConfiguration in $deviceConfigurations) {
        $assignments = Get-DeviceManagement_DeviceConfigurations_Assignments -DeviceConfigurationId $deviceConfiguration.id 
        if ($assignments) {
            $fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Configurations\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Configuration Assignments"
                "Name"   = $deviceConfiguration.displayName
                "Path"   = "Device Configurations\Assignments\$fileName.json"
            }
        }
    }
}