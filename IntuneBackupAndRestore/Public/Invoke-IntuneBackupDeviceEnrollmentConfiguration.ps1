function Invoke-IntuneBackupDeviceEnrollmentConfiguration {
    <#
    .SYNOPSIS
    Backup Intune Device Enrollment Configurations (Enrollment Restrictions and ESP)

    .DESCRIPTION
    Backup Intune Device Enrollment Configurations including Enrollment Restrictions and Enrollment Status Page profiles as JSON files per configuration to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupDeviceEnrollmentConfiguration -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get all Device Enrollment Configurations
    $enrollmentConfigurations = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations" | Get-MGGraphAllPages

    if ($enrollmentConfigurations -and $enrollmentConfigurations.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Enrollment Configurations")) {
            $null = New-Item -Path "$Path\Device Enrollment Configurations" -ItemType Directory
        }

        foreach ($enrollmentConfiguration in $enrollmentConfigurations) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $enrollmentConfiguration.displayName
            } else {
                $fileName = ($enrollmentConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $enrollmentConfiguration | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Device Enrollment Configurations\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Enrollment Configuration"
                "Name"   = $enrollmentConfiguration.displayName
                "Path"   = "Device Enrollment Configurations\$fileName.json"
            }
        }
    }
}
