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
    if (-not (Test-Path "$Path\Device Management Intents")) {
        $null = New-Item -Path "$Path\Device Management Intents" -ItemType Directory
    }

    Write-Verbose "Requesting Intents"
    $intents = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/intents" | Get-MSGraphAllPages

    foreach ($intent in $intents) {
        # Get the corresponding Device Management Template
        Write-Verbose "Requesting Template"
        $template = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/templates/$($intent.templateId)"
        $templateDisplayName = ($template.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        if (-not (Test-Path "$Path\Device Management Intents\$templateDisplayName")) {
            $null = New-Item -Path "$Path\Device Management Intents\$templateDisplayName" -ItemType Directory
        }
        
        # Get all setting categories in the Device Management Template
        Write-Verbose "Requesting Template Categories"
        $templateCategories = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/templates/$($intent.templateId)/categories" | Get-MSGraphAllPages

        $intentSettingsDelta = @()
        foreach ($templateCategory in $templateCategories) {
            # Get all configured values for the template categories
            Write-Verbose "Requesting Intent Setting Values"
            $intentSettingsDelta += (Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/intents/$($intent.id)/categories/$($templateCategory.id)/settings").value
        }

        $intentBackupValue = @{
            "displayName" = $intent.displayName
            "description" = $intent.description
            "settingsDelta" = $intentSettingsDelta
            "roleScopeTagIds" = $intent.roleScopeTagIds
        }
        
        $fileName = ("$($template.id)_$($intent.displayName)").Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $intentBackupValue | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Intents\$templateDisplayName\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Management Intent"
            "Name"   = $intent.displayName
            "Path"   = "Device Management Intents\$templateDisplayName\$fileName.json"
        }
    }
}
