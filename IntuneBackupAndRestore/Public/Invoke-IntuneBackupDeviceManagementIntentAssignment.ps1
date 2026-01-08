function Invoke-IntuneBackupDeviceManagementIntentAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Management Intent Assignments

    .DESCRIPTION
    Backup Intune Device Management Intent Assignments (Endpoint Security policy assignments) as JSON files per Intent to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupDeviceManagementIntentAssignment -Path "C:\temp"
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

    Write-Verbose "Requesting Device Management Intents"
    $intents = Get-MgBetaDeviceManagementIntent -all

    if ($intents -and $intents.Count -gt 0) {

        foreach ($intent in $intents) {
            # Get the corresponding Device Management Template
            Write-Verbose "Requesting Template for Intent: $($intent.displayName)"
            $template = Get-MgBetaDeviceManagementTemplate -DeviceManagementTemplateId $($intent.templateId)

            $templateDisplayName = ($template.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

            # Create folder if not exists
            if (-not (Test-Path "$Path\Device Management Intents\$templateDisplayName")) {
                $null = New-Item -Path "$Path\Device Management Intents\$templateDisplayName" -ItemType Directory
            }

            # Get intent assignments
            Write-Verbose "Requesting Assignments for Intent: $($intent.displayName)"
            $intentAssignments = Get-MgBetaDeviceManagementIntentAssignment -DeviceManagementIntentId $intent.id -all

            if ($intentAssignments -and $intentAssignments.Count -gt 0) {
                $fileName = ("$($template.id)_$($intent.displayName)").Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
                $intentAssignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Device Management Intents\$templateDisplayName\Assignments\$fileName.json"

                [PSCustomObject]@{
                    "Action" = "Backup"
                    "Type"   = "Device Management Intent Assignment"
                    "Name"   = $intent.displayName
                    "Path"   = "Device Management Intents\$templateDisplayName\Assignments\$fileName.json"
                }
            }
        }
    }
}
