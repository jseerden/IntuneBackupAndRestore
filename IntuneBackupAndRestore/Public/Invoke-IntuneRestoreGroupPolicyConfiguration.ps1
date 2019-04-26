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
        [string]$Path
    )

    # Get all Group Policy Configurations
    $groupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates" -File
    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyConfigurationContent = Get-Content -LiteralPath $groupPolicyConfiguration.FullName -Raw | ConvertFrom-Json     

        # Restore the Group Policy Configuration
        try {
            $groupPolicyConfigurationRequestBody = @{
                displayName = $groupPolicyConfiguration.BaseName
            }

            $groupPolicyConfigurationObject = New-GraphGroupPolicyConfiguration -RequestBody ($groupPolicyConfigurationRequestBody | ConvertTo-Json) -ErrorAction Stop
            Write-Output "$($groupPolicyConfigurationObject.displayName) - Successfully restored base Group Policy Configuration"

            foreach ($groupPolicyConfigurationSetting in $groupPolicyConfigurationContent) {
                $groupPolicyDefinitionValue = New-GraphGroupPolicyDefinitionValue -Id $groupPolicyConfigurationObject.id -RequestBody ($groupPolicyConfigurationSetting | ConvertTo-Json -Depth 5) -ErrorAction Stop
                $groupPolicyDefinition = Get-GraphGroupPolicyDefinition -GroupPolicyConfigurationId $groupPolicyConfigurationObject.id -GroupPolicyDefinitionValueId $groupPolicyDefinitionValue.id
                Write-Output "$($groupPolicyConfigurationObject.displayName) - Successfully restored '$($groupPolicyDefinition.displayName)' Setting for Group Policy Configuration"
            }
        }
        catch {
            Write-Output "$($groupPolicyConfiguration.BaseName) - Failed to restore Group Policy Configuration and/or (one or more) Settings"
            Write-Error $_ -ErrorAction Continue
        }
    }
}