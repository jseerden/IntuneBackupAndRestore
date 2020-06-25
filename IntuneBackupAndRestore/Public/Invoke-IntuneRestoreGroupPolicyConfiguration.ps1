function Invoke-IntuneRestoreGroupPolicyConfiguration {
    <#
    .SYNOPSIS
    Restore Intune Group Policy Configurations
    
    .DESCRIPTION
    Restore Intune Group Policy Configurations from JSON files per Group Policy Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupGroupPolicyConfigurations function
    
    .EXAMPLE
    Invoke-IntuneRestoreGroupPolicyConfiguration -Path "C:\temp" -RestoreById $true
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

    # Get all Group Policy Configurations
    $groupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates" -File

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyConfigurationContent = Get-Content -LiteralPath $groupPolicyConfiguration.FullName -Raw | ConvertFrom-Json
        
        # Remove properties that are not available for creating a new configuration
        $requestBody = ($groupPolicyConfigurationContent | ConvertTo-Json).toString()

        # Restore the Group Policy Configuration
        try {
            $groupPolicyConfigurationRequestBody = @{
                displayName = $groupPolicyConfiguration.BaseName
            }
            $groupPolicyConfigurationObject = Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/groupPolicyConfigurations" -Content ($groupPolicyConfigurationRequestBody | ConvertTo-Json).toString() -ErrorAction Stop
            Write-Output "$($groupPolicyConfigurationObject.displayName) - Successfully restored base Group Policy Configuration"

            foreach ($groupPolicyConfigurationSetting in $groupPolicyConfigurationContent) {
                $groupPolicyDefinitionValue = Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/definitionValues" -Content ($groupPolicyConfigurationSetting | ConvertTo-Json -Depth 5).toString() -ErrorAction Stop
                $groupPolicyDefinition = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/definitionValues/$($groupPolicyDefinitionValue.id)/definition"
                Write-Output "$($groupPolicyConfigurationObject.displayName) - Successfully restored '$($groupPolicyDefinition.displayName)' Setting for Group Policy Configuration"
            }
        }
        catch {
            Write-Output "$($groupPolicyConfiguration.BaseName) - Failed to restore Group Policy Configuration and/or (one or more) Settings"
            Write-Error $_ -ErrorAction Continue
        }
    }
}