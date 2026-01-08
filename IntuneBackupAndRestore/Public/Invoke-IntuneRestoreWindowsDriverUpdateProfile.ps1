function Invoke-IntuneRestoreWindowsDriverUpdateProfile {
    <#
    .SYNOPSIS
    Restore Intune Windows Driver Update Profiles

    .DESCRIPTION
    Restore Intune Windows Driver Update Profiles from JSON files per profile from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupWindowsDriverUpdateProfile function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreWindowsDriverUpdateProfile -Path "C:\temp"
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

    # Get all Windows Driver Update Profiles
    $driverUpdateProfiles = Get-ChildItem -Path "$Path\Windows Driver Update Profiles" -File -ErrorAction SilentlyContinue

    foreach ($driverUpdateProfile in $driverUpdateProfiles) {
        $driverUpdateProfileContent = Get-Content -LiteralPath $driverUpdateProfile.FullName -Raw | ConvertFrom-Json

        $driverUpdateProfileDisplayName = $driverUpdateProfileContent.displayName

        # Remove properties that are not available for creating a new profile
        $requestBody = $driverUpdateProfileContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Windows Driver Update Profile
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Driver Update Profile"
                "Name"   = $driverUpdateProfileDisplayName
                "Path"   = "Windows Driver Update Profiles\$($driverUpdateProfile.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$driverUpdateProfileDisplayName - Failed to restore Windows Driver Update Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
