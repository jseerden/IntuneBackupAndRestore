function Invoke-IntuneRestoreWindowsFeatureUpdateProfile {
    <#
    .SYNOPSIS
    Restore Intune Windows Feature Update Profiles

    .DESCRIPTION
    Restore Intune Windows Feature Update Profiles from JSON files per profile from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupWindowsFeatureUpdateProfile function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreWindowsFeatureUpdateProfile -Path "C:\temp"
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
        connect-mggraph -scopes "DeviceManagementConfiguration.ReadWrite.All"
    }

    # Get all Windows Feature Update Profiles
    $featureUpdateProfiles = Get-ChildItem -Path "$Path\Windows Feature Update Profiles" -File -ErrorAction SilentlyContinue

    foreach ($featureUpdateProfile in $featureUpdateProfiles) {
        $featureUpdateProfileContent = Get-Content -LiteralPath $featureUpdateProfile.FullName -Raw | ConvertFrom-Json

        $featureUpdateProfileDisplayName = $featureUpdateProfileContent.displayName

        # Remove properties that are not available for creating a new profile
        $requestBody = $featureUpdateProfileContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, endOfSupportDate, deployableContentDisplayName

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Windows Feature Update Profile
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Feature Update Profile"
                "Name"   = $featureUpdateProfileDisplayName
                "Path"   = "Windows Feature Update Profiles\$($featureUpdateProfile.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$featureUpdateProfileDisplayName - Failed to restore Windows Feature Update Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
