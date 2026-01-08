function Invoke-IntuneBackupIntuneBrandingProfile {
    <#
    .SYNOPSIS
    Backup Intune Branding Profiles

    .DESCRIPTION
    Backup Intune Branding Profiles (Company Portal customization) as JSON files per profile to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupIntuneBrandingProfile -Path "C:\temp"
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
        Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All"
    }

    # Get all Intune Branding Profiles
    $brandingProfiles = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/intuneBrandingProfiles" | Get-MGGraphAllPages

    if ($brandingProfiles -and $brandingProfiles.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Intune Branding Profiles")) {
            $null = New-Item -Path "$Path\Intune Branding Profiles" -ItemType Directory
        }

        foreach ($brandingProfile in $brandingProfiles) {
            # Skip if profileName is null or empty
            if ([string]::IsNullOrEmpty($brandingProfile.profileName)) {
                Write-Warning "Skipping Intune Branding Profile with null or empty profileName (ID: $($brandingProfile.id))"
                continue
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $brandingProfile.profileName
            } else {
                $fileName = ($brandingProfile.profileName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $brandingProfile | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Intune Branding Profiles\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Intune Branding Profile"
                "Name"   = $brandingProfile.profileName
                "Path"   = "Intune Branding Profiles\$fileName.json"
            }
        }
    }
}
