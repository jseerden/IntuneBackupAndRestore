function Invoke-IntuneRestoreIntuneBrandingProfile {
    <#
    .SYNOPSIS
    Restore Intune Branding Profiles

    .DESCRIPTION
    Restore Intune Branding Profiles (Company Portal branding) from JSON files per profile from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupIntuneBrandingProfile function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreIntuneBrandingProfile -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get all Intune Branding Profiles
    $brandingProfiles = Get-ChildItem -Path "$Path\Intune Branding Profiles" -File -ErrorAction SilentlyContinue

    foreach ($brandingProfile in $brandingProfiles) {
        $brandingProfileContent = Get-Content -LiteralPath $brandingProfile.FullName -Raw | ConvertFrom-Json

        $brandingProfileName = $brandingProfileContent.profileName

        # Skip the default branding profile (can only be updated, not created)
        if ($brandingProfileName -like "Default*" -or $brandingProfileContent.id -eq "00000000-0000-0000-0000-000000000000") {
            Write-Verbose "Skipping built-in Branding Profile: $brandingProfileName" -Verbose
            continue
        }

        # Remove properties that are not available for creating a new profile
        $requestBody = $brandingProfileContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, isDefaultProfile

        # Validate profileName length (max 40 characters for Intune Branding Profiles - uses profileName not displayName)
        if ($requestBody.profileName.Length -gt 40) {
            Write-Warning "$brandingProfileName - Profile name exceeds 40 characters, truncating..."
            $requestBody.profileName = $requestBody.profileName.Substring(0, 37) + "..."
        }

        # Validate displayName length (max 40 characters for Intune Branding Profiles)
        if ($requestBody.displayName -and $requestBody.displayName.Length -gt 40) {
            Write-Warning "$brandingProfileName - Display name exceeds 40 characters, truncating..."
            $requestBody.displayName = $requestBody.displayName.Substring(0, 37) + "..."
        }

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Intune Branding Profile
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/intuneBrandingProfiles"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Intune Branding Profile"
                "Name"   = $brandingProfileName
                "Path"   = "Intune Branding Profiles\$($brandingProfile.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$brandingProfileName - Failed to restore Intune Branding Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
