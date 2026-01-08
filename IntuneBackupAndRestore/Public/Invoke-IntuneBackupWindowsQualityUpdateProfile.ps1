function Invoke-IntuneBackupWindowsQualityUpdateProfile {
    <#
    .SYNOPSIS
    Backup Windows Quality Update Profiles

    .DESCRIPTION
    Backup Windows Quality Update Profiles as JSON files per profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupWindowsQualityUpdateProfile -Path "C:\temp"
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

    # Get all Windows Quality Update Profiles
    $qualityUpdateProfiles = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles" | Get-MGGraphAllPages

    if ($qualityUpdateProfiles -and $qualityUpdateProfiles.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Windows Quality Update Profiles")) {
            $null = New-Item -Path "$Path\Windows Quality Update Profiles" -ItemType Directory
        }

        foreach ($qualityUpdateProfile in $qualityUpdateProfiles) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $qualityUpdateProfile.displayName
            } else {
                $fileName = ($qualityUpdateProfile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $qualityUpdateProfile | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Windows Quality Update Profiles\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Windows Quality Update Profile"
                "Name"   = $qualityUpdateProfile.displayName
                "Path"   = "Windows Quality Update Profiles\$fileName.json"
            }
        }
    }
}
