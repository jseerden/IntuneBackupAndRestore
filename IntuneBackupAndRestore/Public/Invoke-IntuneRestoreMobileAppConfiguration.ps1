function Invoke-IntuneRestoreMobileAppConfiguration {
    <#
    .SYNOPSIS
    Restore Intune Mobile App Configurations

    .DESCRIPTION
    Restore Intune Mobile App Configurations (device-level, iOS/Android) from JSON files per configuration from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupMobileAppConfiguration function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreMobileAppConfiguration -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "v1.0"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All"
    }

    # Get all Mobile App Configurations
    $mobileAppConfigurations = Get-ChildItem -Path "$Path\Mobile App Configurations" -File -ErrorAction SilentlyContinue

    foreach ($mobileAppConfiguration in $mobileAppConfigurations) {
        $mobileAppConfigurationContent = Get-Content -LiteralPath $mobileAppConfiguration.FullName -Raw | ConvertFrom-Json

        $mobileAppConfigurationDisplayName = $mobileAppConfigurationContent.displayName

        # Remove properties that are not available for creating a new configuration
        $requestBody = $mobileAppConfigurationContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Mobile App Configuration
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceAppManagement/mobileAppConfigurations"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Mobile App Configuration"
                "Name"   = $mobileAppConfigurationDisplayName
                "Path"   = "Mobile App Configurations\$($mobileAppConfiguration.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$mobileAppConfigurationDisplayName - Failed to restore Mobile App Configuration" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
