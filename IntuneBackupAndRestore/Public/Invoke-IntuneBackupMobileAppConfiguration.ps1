function Invoke-IntuneBackupMobileAppConfiguration {
    <#
    .SYNOPSIS
    Backup Mobile App Configurations (Device-level)

    .DESCRIPTION
    Backup Mobile App Configurations (iOS, Android) as JSON files per configuration to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupMobileAppConfiguration -Path "C:\temp"
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

    # Get all Mobile App Configurations
    $mobileAppConfigurations = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceAppManagement/mobileAppConfigurations" | Get-MGGraphAllPages

    if ($mobileAppConfigurations -and $mobileAppConfigurations.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Mobile App Configurations")) {
            $null = New-Item -Path "$Path\Mobile App Configurations" -ItemType Directory
        }

        foreach ($mobileAppConfiguration in $mobileAppConfigurations) {
            # Skip if displayName is null or empty
            if ([string]::IsNullOrEmpty($mobileAppConfiguration.displayName)) {
                Write-Warning "Skipping Mobile App Configuration with null or empty displayName (ID: $($mobileAppConfiguration.id))"
                continue
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $mobileAppConfiguration.displayName
            } else {
                $fileName = ($mobileAppConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $mobileAppConfiguration | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Mobile App Configurations\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Mobile App Configuration"
                "Name"   = $mobileAppConfiguration.displayName
                "Path"   = "Mobile App Configurations\$fileName.json"
            }
        }
    }
}
