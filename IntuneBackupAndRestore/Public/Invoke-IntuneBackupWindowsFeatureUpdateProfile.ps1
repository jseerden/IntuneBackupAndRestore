function Invoke-IntuneBackupWindowsFeatureUpdateProfile {
    <#
    .SYNOPSIS
    Backup Windows Feature Update Profiles

    .DESCRIPTION
    Backup Windows Feature Update Profiles as JSON files per profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupWindowsFeatureUpdateProfile -Path "C:\temp"
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

    # Get all Windows Feature Update Profiles
    $featureUpdateProfiles = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles" | Get-MGGraphAllPages

    if ($featureUpdateProfiles -and $featureUpdateProfiles.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Windows Feature Update Profiles")) {
            $null = New-Item -Path "$Path\Windows Feature Update Profiles" -ItemType Directory
        }

        foreach ($featureUpdateProfile in $featureUpdateProfiles) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $featureUpdateProfile.displayName
            } else {
                $fileName = ($featureUpdateProfile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $featureUpdateProfile | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Windows Feature Update Profiles\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Windows Feature Update Profile"
                "Name"   = $featureUpdateProfile.displayName
                "Path"   = "Windows Feature Update Profiles\$fileName.json"
            }
        }
    }
}
