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

    # Create folder if not exists
    if (-not (Test-Path "$Path\Administrative Templates")) {
        $null = New-Item -Path "$Path\Administrative Templates" -ItemType Directory
    }

    # Get all Group Policy Configurations
    $groupPolicyConfigurations = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/groupPolicyConfigurations" | Get-MSGraphAllPages

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyDefinitionValues = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/definitionValues" | Get-MSGraphAllPages
        $groupPolicyBackupValues = @()

        foreach ($groupPolicyDefinitionValue in $groupPolicyDefinitionValues) {
            $groupPolicyDefinition = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/definitionValues/$($groupPolicyDefinitionValue.id)/definition"
            $groupPolicyPresentationValues = (Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/definitionValues/$($groupPolicyDefinitionValue.id)/presentationValues?`$expand=presentation").Value | Select-Object -Property * -ExcludeProperty lastModifiedDateTime, createdDateTime
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

        $fileName = ($groupPolicyConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $groupPolicyBackupValues | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Administrative Templates\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Administrative Template"
            "Name"   = $groupPolicyConfiguration.displayName
            "Path"   = "Administrative Templates\$fileName.json"
        }
    }
}
