function Invoke-IntuneBackupConfigurationPolicy {
    <#
    .SYNOPSIS
    Backup Intune Settings Catalog Policies
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policies as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicy -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    Select-MgProfile -Name $ApiVersion

    # Create folder if not exists
    if (-not (Test-Path "$Path\Settings Catalog")) {
        $null = New-Item -Path "$Path\Settings Catalog" -ItemType Directory
    }

    # Get all Setting Catalogs Policies
    $configurationPolicies = Get-MgDeviceManagementConfigurationPolicy -All 

    foreach ($configurationPolicy in $configurationPolicies) {
        $settings = Get-MgDeviceManagementConfigurationPolicySetting -DeviceManagementConfigurationPolicyId $configurationPolicy.id -All | ConvertTo-Json

        if ($settings -isnot [System.Array]) {
            $configurationPolicy.Settings = @($settings)
        } else {
            $configurationPolicy.Settings = $settings
        }
        
        $fileName = ($configurationPolicy.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $configurationPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Settings Catalog\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Settings Catalog"
            "Name"   = $configurationPolicy.name
            "Path"   = "Settings Catalog\$fileName.json"
        }
    }
}
