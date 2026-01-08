function Invoke-IntuneRestoreTargetedManagedAppConfiguration {
    <#
    .SYNOPSIS
    Restore Intune Targeted Managed App Configurations

    .DESCRIPTION
    Restore Intune Targeted Managed App Configurations (app-level MAM) from JSON files per configuration from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupTargetedManagedAppConfiguration function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreTargetedManagedAppConfiguration -Path "C:\temp"
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
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All"
    }

    # Get all Targeted Managed App Configurations
    $targetedManagedAppConfigurations = Get-ChildItem -Path "$Path\Targeted Managed App Configurations" -File -ErrorAction SilentlyContinue

    foreach ($targetedManagedAppConfiguration in $targetedManagedAppConfigurations) {
        $targetedManagedAppConfigurationContent = Get-Content -LiteralPath $targetedManagedAppConfiguration.FullName -Raw | ConvertFrom-Json

        $targetedManagedAppConfigurationDisplayName = $targetedManagedAppConfigurationContent.displayName

        # Remove properties that are not available for creating a new configuration
        $requestBody = $targetedManagedAppConfigurationContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Targeted Managed App Configuration
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceAppManagement/targetedManagedAppConfigurations"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Targeted Managed App Configuration"
                "Name"   = $targetedManagedAppConfigurationDisplayName
                "Path"   = "Targeted Managed App Configurations\$($targetedManagedAppConfiguration.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$targetedManagedAppConfigurationDisplayName - Failed to restore Targeted Managed App Configuration" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
