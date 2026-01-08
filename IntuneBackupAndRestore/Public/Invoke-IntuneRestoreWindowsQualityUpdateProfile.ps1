function Invoke-IntuneRestoreWindowsQualityUpdateProfile {
    <#
    .SYNOPSIS
    Restore Intune Windows Quality Update Profiles

    .DESCRIPTION
    Restore Intune Windows Quality Update Profiles from JSON files per profile from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupWindowsQualityUpdateProfile function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreWindowsQualityUpdateProfile -Path "C:\temp"
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

    # Get all Windows Quality Update Profiles
    $qualityUpdateProfiles = Get-ChildItem -Path "$Path\Windows Quality Update Profiles" -File -ErrorAction SilentlyContinue

    foreach ($qualityUpdateProfile in $qualityUpdateProfiles) {
        $qualityUpdateProfileContent = Get-Content -LiteralPath $qualityUpdateProfile.FullName -Raw | ConvertFrom-Json

        $qualityUpdateProfileDisplayName = $qualityUpdateProfileContent.displayName

        # Remove properties that are not available for creating a new profile
        $requestBody = $qualityUpdateProfileContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Windows Quality Update Profile
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Quality Update Profile"
                "Name"   = $qualityUpdateProfileDisplayName
                "Path"   = "Windows Quality Update Profiles\$($qualityUpdateProfile.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$qualityUpdateProfileDisplayName - Failed to restore Windows Quality Update Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
