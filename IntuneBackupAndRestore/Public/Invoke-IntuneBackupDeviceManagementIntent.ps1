function Invoke-IntuneBackupDeviceManagementIntent {
    <#
    .SYNOPSIS
    Backup Intune Device Management Intents
    
    .DESCRIPTION
    Backup Intune Device Management Intents as JSON files per Device Management Intent to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceManagementIntent -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Management Intents")) {
        $null = New-Item -Path "$Path\Device Management Intents" -ItemType Directory
    }

    $intents = Get-GraphDeviceManagementIntent

    foreach ($intent in $intents) {
        # Get the corresponding Device Management Template
        $template = Get-GraphDeviceManagementTemplate -Id $intent.templateId
        $templateDisplayName = ($template.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        Write-Output "Backing Up - Device Management Intent ($($template.displayName)): $($intent.displayName)"

        if (-not (Test-Path "$Path\Device Management Intents\$templateDisplayName")) {
            $null = New-Item -Path "$Path\Device Management Intents\$templateDisplayName" -ItemType Directory
        }
        
        # Get all setting categories in the Device Management Template
        $templateCategories = Get-GraphDeviceManagementTemplateSettingCategory -Id $intent.templateId
        $intentSettingsDelta = @()
        foreach ($templateCategory in $templateCategories) {
            # Get all configured values for the template categories
            $intentSettingsDelta += Get-GraphDeviceManagementIntentSettingValue -Id $intent.id -CategoryId $templateCategory.id
        }

        $intentBackupValue = @{
            "displayName" = $intent.displayName
            "description" = $intent.description
            "settingsDelta" = $intentSettingsDelta
            "roleScopeTagIds" = $intent.roleScopeTagIds
        }
        
        $deviceManagementIntentFileName = ("$($template.id)_$($template.displayName)_$($intent.displayName)_$($intent.id)").Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $intentBackupValue | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Intents\$templateDisplayName\$deviceManagementIntentFileName.json"
    }
}