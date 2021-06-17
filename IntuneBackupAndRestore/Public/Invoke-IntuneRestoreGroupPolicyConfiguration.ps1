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
        
        # Restore the Group Policy Configuration
        try {
            $groupPolicyConfigurationRequestBody = @{
                displayName = $groupPolicyConfiguration.BaseName
            }
            $groupPolicyConfigurationObject = Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/groupPolicyConfigurations" -Content ($groupPolicyConfigurationRequestBody | ConvertTo-Json).toString() -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Administrative Template"
                "Name"   = $groupPolicyConfigurationObject.displayName
                "Path"   = "Administrative Templates\$($groupPolicyConfiguration.Name)"
            }

            foreach ($groupPolicyConfigurationSetting in $groupPolicyConfigurationContent) {
                $groupPolicyDefinitionValue = Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/definitionValues" -Content ($groupPolicyConfigurationSetting | ConvertTo-Json -Depth 100).toString() -ErrorAction Stop
                $groupPolicyDefinition = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/definitionValues/$($groupPolicyDefinitionValue.id)/definition"
                [PSCustomObject]@{
                    "Action" = "Restore"
                    "Type"   = "Administrative Template Setting"
                    "Name"   = $groupPolicyDefinition.displayName
                    "Path"   = "Administrative Templates\$($groupPolicyConfiguration.Name)"
                }
            }
        }
        catch {
            Write-Verbose "$($groupPolicyConfiguration.BaseName) - Failed to restore Group Policy Configuration and/or (one or more) Settings" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}