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
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all device management intents
    $deviceManagementIntents = Get-ChildItem -Path "$Path\Device Management Intents" -Recurse -File -Filter *.json
    foreach ($deviceManagementIntent in $deviceManagementIntents) {
        $deviceManagementIntentContent = Get-Content -LiteralPath $deviceManagementIntent.FullName -Raw
        $deviceManagementIntentDisplayName = ($deviceManagementIntentContent | ConvertFrom-Json).displayName
        $templateId = $deviceManagementIntent.Name.Split("_")[0]
        $templateDisplayName = ($deviceManagementIntent).DirectoryName.Split('\')[-1]

        if($RestoreById)
        { 
            # Get current ID of Intent
            $deviceManagementIntentId = $null
            $deviceManagementIntentId = ((Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/intents").Value | Where-Object{$_.displayName -eq $deviceManagementIntentDisplayName}).Id
        }
        
        # Restore the device management intent
        try {
            if($RestoreById -and $deviceManagementIntentId)
            {   
                if($deviceManagementIntentId.count -gt 1){Throw "Multiple Intents found with same Display Name - cannot continue"}
                $deviceManagementIntentContent.toString()
                $($deviceManagementIntentId)
                $null = Invoke-MSGraphRequest -HttpMethod PATCH -Url "deviceManagement/intents/$($deviceManagementIntentId)" -Content $deviceManagementIntentContent.toString() -ErrorAction Stop
            }
            else 
            {
                $null = Invoke-MSGraphRequest -HttpMethod POST -Url "deviceManagement/templates/$($templateId)/createInstance" -Content $deviceManagementIntentContent.toString() -ErrorAction Stop
                [PSCustomObject]@{
                    "Action" = "Restore"
                    "Type"   = "Device Management Intent"
                    "Name"   = $deviceManagementIntentDisplayName
                    "Path"   = "Device Management Intents\$($deviceManagementIntent.Name)"
                }
            }
        }
        catch {
            Write-Verbose "$deviceManagementIntentDisplayName - Failed to restore Device Management Intent ($templateDisplayName)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
