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
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"

    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all device management intents
    $deviceManagementIntents = Get-ChildItem -Path "$Path\Device Management Intents" -Recurse -File -ErrorAction SilentlyContinue

    #Used to exclude Onboarding/Offboarding blob settings if AutoPopulateOnboardingBlob is set to $true
    $excludedEDRDefinitions = @(
        "deviceConfiguration--windowsDefenderAdvancedThreatProtectionConfiguration_advancedThreatProtectionBlobType"
        "deviceConfiguration--windowsDefenderAdvancedThreatProtectionConfiguration_advancedThreatProtectionOffboardingBlob"
        "deviceConfiguration--windowsDefenderAdvancedThreatProtectionConfiguration_advancedThreatProtectionOnboardingBlob"
        "deviceConfiguration--windowsDefenderAdvancedThreatProtectionConfiguration_advancedThreatProtectionOnboardingFilename"
        "deviceConfiguration--windowsDefenderAdvancedThreatProtectionConfiguration_advancedThreatProtectionOffboardingFilename"
    )

    foreach ($deviceManagementIntent in $deviceManagementIntents) {
        if($deviceManagementIntent.DirectoryName -match "Assignments"){continue}
        $deviceManagementIntentContent = Get-Content -LiteralPath $deviceManagementIntent.FullName | ConvertFrom-Json
        $templateId = $deviceManagementIntent.Name.Split("_")[0]
        $templateDisplayName = ($deviceManagementIntent).DirectoryName.Split('\')[-1]

        $deviceManagementIntentDisplayName = $deviceManagementIntentContent.displayName

        #When importing an EDR policy, if AutoPopulateOnboardingBlob is set to true, the onboarding blob policies need to be set to null or removed.
        If ($templateId -eq "e44c2ca3-2f9a-400a-a113-6cc88efd773d") {
            $AutoPopulateOnboardingBlob = ($deviceManagementIntentContent.settingsDelta | ? { $_.definitionId -eq "deviceConfiguration--windowsDefenderAdvancedThreatProtectionConfiguration_advancedThreatProtectionAutoPopulateOnboardingBlob" }).value
            If ($AutoPopulateOnboardingBlob) {
                $deviceManagementIntentContent.settingsDelta = $deviceManagementIntentContent.settingsDelta | ? { $excludedEDRDefinitions -notcontains $_.definitionId }
            }
        }
        
        $deviceManagementIntentJson = $($deviceManagementIntentContent | convertto-json -Depth 100)
        # Restore the device management intent
        try {
            New-MgBetaDeviceManagementTemplateInstance -DeviceManagementTemplateId $templateId -BodyParameter $deviceManagementIntentJson
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Intent"
                "Name"   = $deviceManagementIntentDisplayName
                "Path"   = "Device Management Intents\$($deviceManagementIntent.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceManagementIntentDisplayName - Failed to restore Device Management Intent ($templateDisplayName)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
