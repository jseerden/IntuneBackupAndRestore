function Invoke-IntuneBackupDeviceHealthScript {
    <#
    .SYNOPSIS
    Backup Intune Health Scripts (Remediation scripts)

    .DESCRIPTION
    Backup Intune Health Scripts (Remediation scripts) as JSON files per Health Script to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .EXAMPLE
    Invoke-IntuneBackupDeviceHealthScript -Path "C:\temp"
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
    if($null -eq (Get-MgContext)){
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MgProfile).name -eq $apiVersion)) {
        Select-MgProfile -Name "beta"
    }
    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Health Scripts")) {
        $null = New-Item -Path "$Path\Device Health Scripts" -ItemType Directory
    }

    $healthScripts = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts" | Get-MGGraphAllPages

    foreach ($healthScript in $healthScripts) {
        $fileName = ($healthScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        # Export the Health script profile
        $healthScript | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Health Scripts\$fileName.json"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Health Scripts\Script Content")) {
            $null = New-Item -Path "$Path\Device Health Scripts\Script Content" -ItemType Directory
        }

        $healthScriptObject = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$($healthScript.id)"
        $healthScriptDetectionContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($healthScriptObject.detectionScriptContent))
        $healthScriptDetectionContent | Out-File -LiteralPath "$path\Device Health Scripts\Script Content\$fileName`_detection.ps1"
        $healthScriptRemediationContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($healthScriptObject.remediationScriptContent))
        $healthScriptRemediationContent | Out-File -LiteralPath "$path\Device Health Scripts\Script Content\$fileName`_remediation.ps1"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Health Scripts"
            "Name"   = $healthScript.displayName
            "Path"   = "Device Health Scripts\$fileName.json"
        }
    }
}
