function Invoke-IntuneRestoreConfigurationPolicy {
    <#
    .SYNOPSIS
    Restore Intune Settings Catalog Policies
    
    .DESCRIPTION
    Restore Intune Settings Catalog Policies from JSON files per Settings Catalog Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupConfigurationPolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreConfigurationPolicy -Path "C:\temp"
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
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all Settings Catalog Policies
    $configurationPolicies = Get-ChildItem -Path "$Path\Settings Catalog" -File

    foreach ($configurationPolicy in $configurationPolicies) {
        $configurationPolicyContent = Get-Content -LiteralPath $configurationPolicy.FullName -Raw | ConvertFrom-Json
        
        # Remove properties that are not available for creating a new configuration
        $requestBody = $configurationPolicyContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, settingCount, creationSource | ConvertTo-Json -Depth 100

        # Restore the Settings Catalog Policy
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/configurationPolicies" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Settings Catalog"
                "Name"   = $configurationPolicy.FullName
                "Path"   = "Settings Catalog\$($configurationPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$($configurationPolicy.FullName) - Failed to restore Settings Catalog Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}