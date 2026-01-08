function Invoke-IntuneBackupWindowsDriverUpdateProfile {
    <#
    .SYNOPSIS
    Backup Windows Driver Update Profiles

    .DESCRIPTION
    Backup Windows Driver Update Profiles as JSON files per profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupWindowsDriverUpdateProfile -Path "C:\temp"
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
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"
    }

    # Get all Windows Driver Update Profiles
    $driverUpdateProfiles = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles" | Get-MGGraphAllPages

    if ($driverUpdateProfiles -and $driverUpdateProfiles.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Windows Driver Update Profiles")) {
            $null = New-Item -Path "$Path\Windows Driver Update Profiles" -ItemType Directory
        }

        foreach ($driverUpdateProfile in $driverUpdateProfiles) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $driverUpdateProfile.displayName
            } else {
                $fileName = ($driverUpdateProfile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $driverUpdateProfile | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Windows Driver Update Profiles\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Windows Driver Update Profile"
                "Name"   = $driverUpdateProfile.displayName
                "Path"   = "Windows Driver Update Profiles\$fileName.json"
            }
        }
    }
}
