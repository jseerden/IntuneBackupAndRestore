function Invoke-IntuneBackupGroupPolicyConfiguration {
    <#
    .SYNOPSIS
    Backup Intune Group Policy Configurations
    
    .DESCRIPTION
    Backup Intune Group Policy Configurations as JSON files per Group Policy Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupGroupPolicyConfiguration -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Administrative Templates")) {
        $null = New-Item -Path "$Path\Administrative Templates" -ItemType Directory
    }

    # Get all Group Policy Configurations
    $groupPolicyConfigurations = Get-GraphGroupPolicyConfiguration

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyDefinitionValues = Get-GraphGroupPolicyDefinitionValue -GroupPolicyConfigurationId $groupPolicyConfiguration.id

        $groupPolicyBackupValues = @()

        foreach ($groupPolicyDefinitionValue in $groupPolicyDefinitionValues.Value) {
            $groupPolicyDefinition = Get-GraphGroupPolicyDefinition -GroupPolicyConfigurationId $groupPolicyConfiguration.id -GroupPolicyDefinitionValueId $groupPolicyDefinitionValue.id
            $groupPolicyPresentationValues = (Get-GraphGroupPolicyPresentationValue -GroupPolicyConfigurationId $groupPolicyConfiguration.id -GroupPolicyDefinitionValueId $groupPolicyDefinitionValue.id).Value | Select-Object -Property * -ExcludeProperty lastModifiedDateTime, createdDateTime
            $groupPolicyBackupValue = @{
                "enabled" = $groupPolicyDefinitionValue.enabled
                "definition@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('$($groupPolicyDefinition.id)')"
            }

            if ($groupPolicyPresentationValues.value) {
                $groupPolicyBackupValue."presentationValues" = @()
                foreach ($groupPolicyPresentationValue in $groupPolicyPresentationValues) {
                    $groupPolicyBackupValue."presentationValues" +=
                        @{
                            "@odata.type" = $groupPolicyPresentationValue.'@odata.type'
                            "value" = $groupPolicyPresentationValue.value
                            "presentation@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('$($groupPolicyDefinition.id)')/presentations('$($groupPolicyPresentationValue.presentation.id)')"
                        }
                }
            } elseif ($groupPolicyPresentationValues.values) {
                $groupPolicyBackupValue."presentationValues" = @(
                    @{
                        "@odata.type" = $groupPolicyPresentationValues.'@odata.type'
                        "values" = @(
                            foreach ($groupPolicyPresentationValue in $groupPolicyPresentationValues.values) {
                                @{
                                    "name" = $groupPolicyPresentationValue.name
                                    "value" = $groupPolicyPresentationValue.value
                                }
                            }
                        )
                        "presentation@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('$($groupPolicyDefinition.id)')/presentations('$($groupPolicyPresentationValues.presentation.id)')"
                    }
                )
            }

            $groupPolicyBackupValues += $groupPolicyBackupValue
        }

        Write-Output "Backing Up - Administrative Template: $($groupPolicyConfiguration.displayName)"
        $fileName = ($groupPolicyConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $groupPolicyBackupValues | ConvertTo-Json -Depth 5 | Out-File -LiteralPath "$path\Administrative Templates\$fileName.json"
    }
}
