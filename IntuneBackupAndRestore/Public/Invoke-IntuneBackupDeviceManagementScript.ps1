function Invoke-IntuneBackupDeviceManagementScript {
    <#
    .SYNOPSIS
    Backup Intune Device Management Scripts
    
    .DESCRIPTION
    Backup Intune Device Management Scripts as JSON files per Device Management Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceManagementScript -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Management Scripts\Script Content")) {
        $null = New-Item -Path "$Path\Device Management Scripts\Script Content" -ItemType Directory
    }

    # Get all device management scripts
    $deviceManagementScripts = Get-GraphDeviceManagementScript

    foreach ($deviceManagementScript in $deviceManagementScripts) {
        Write-Output "Backing Up - Device Management Script: $($deviceManagementScript.displayName)"
        # ScriptContent returns null, so we have to query Microsoft Graph for each script
        $deviceManagementScriptObject = Get-GraphDeviceManagementScript -Id $deviceManagementScript.Id
        $deviceManagementScriptFileName = ($deviceManagementScriptObject.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $deviceManagementScriptObject | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Scripts\$deviceManagementScriptFileName.json"

        $deviceManagementScriptContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($deviceManagementScriptObject.scriptContent))
        $deviceManagementScriptContent | Out-File -LiteralPath "$path\Device Management Scripts\Script Content\$deviceManagementScriptFileName.ps1"
    }
}