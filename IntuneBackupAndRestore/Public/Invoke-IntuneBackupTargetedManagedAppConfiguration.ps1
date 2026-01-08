function Invoke-IntuneBackupTargetedManagedAppConfiguration {
    <#
    .SYNOPSIS
    Backup Targeted Managed App Configurations (MAM)

    .DESCRIPTION
    Backup Targeted Managed App Configurations (Mobile Application Management) as JSON files per configuration to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupTargetedManagedAppConfiguration -Path "C:\temp"
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

    # Get all Targeted Managed App Configurations
    $targetedManagedAppConfigurations = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceAppManagement/targetedManagedAppConfigurations" | Get-MGGraphAllPages

    if ($targetedManagedAppConfigurations -and $targetedManagedAppConfigurations.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Targeted Managed App Configurations")) {
            $null = New-Item -Path "$Path\Targeted Managed App Configurations" -ItemType Directory
        }

        foreach ($targetedManagedAppConfiguration in $targetedManagedAppConfigurations) {
            # Skip if displayName is null or empty
            if ([string]::IsNullOrEmpty($targetedManagedAppConfiguration.displayName)) {
                Write-Warning "Skipping Targeted Managed App Configuration with null or empty displayName (ID: $($targetedManagedAppConfiguration.id))"
                continue
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $targetedManagedAppConfiguration.displayName
            } else {
                $fileName = ($targetedManagedAppConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $targetedManagedAppConfiguration | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Targeted Managed App Configurations\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Targeted Managed App Configuration"
                "Name"   = $targetedManagedAppConfiguration.displayName
                "Path"   = "Targeted Managed App Configurations\$fileName.json"
            }
        }
    }
}
