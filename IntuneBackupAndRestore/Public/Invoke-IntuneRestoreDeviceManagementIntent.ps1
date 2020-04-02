function Invoke-IntuneRestoreDeviceManagementIntent {
    <#
    .SYNOPSIS
    Restore Intune Device Management Intents
    
    .DESCRIPTION
    Restore Intune Device Management Intents from JSON files per Device Management Intent from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementIntent function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceManagementIntent -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Get all device management intents
    $deviceManagementIntents = Get-ChildItem -Path "$Path\Device Management Intents" -Recurse -File
    foreach ($deviceManagementIntent in $deviceManagementIntents) {
        $deviceManagementIntentContent = Get-Content -LiteralPath $deviceManagementIntent.FullName -Raw
        $deviceManagementIntentDisplayName = ($deviceManagementIntentContent | ConvertFrom-Json).displayName
        $templateId = $deviceManagementIntent.Name.Split("_")[0]
        $templateDisplayName = $deviceManagementIntent.Name.Split("_")[1]

        # Restore the device management intent
        try {
            $null = New-GraphDeviceManagementTemplateInstance -TemplateId $templateId -RequestBody $deviceManagementIntentContent -ErrorAction Stop
            Write-Output "$deviceManagementIntentDisplayName - Successfully restored Device Management Intent ($templateDisplayName)"
        }
        catch {
            Write-Output "$deviceManagementIntentDisplayName - Failed to restore Device Management Intent ($templateDisplayName)"
            Write-Error $_ -ErrorAction Continue
        }
    }
}