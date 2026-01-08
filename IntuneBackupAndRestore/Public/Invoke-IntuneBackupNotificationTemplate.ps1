function Invoke-IntuneBackupNotificationTemplate {
    <#
    .SYNOPSIS
    Backup Notification Message Templates

    .DESCRIPTION
    Backup Notification Message Templates as JSON files per template to the specified Path.
    These templates are used for compliance notification messages.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneBackupNotificationTemplate -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "v1.0"
    )

    # Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get all Notification Message Templates with localized messages expanded
    $notificationTemplates = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/notificationMessageTemplates?`$expand=localizedNotificationMessages" | Get-MGGraphAllPages

    if ($notificationTemplates -and $notificationTemplates.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Notification Templates")) {
            $null = New-Item -Path "$Path\Notification Templates" -ItemType Directory
        }

        foreach ($notificationTemplate in $notificationTemplates) {
            # Skip if displayName is null or empty
            if ([string]::IsNullOrEmpty($notificationTemplate.displayName)) {
                Write-Warning "Skipping Notification Template with null or empty displayName (ID: $($notificationTemplate.id))"
                continue
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $notificationTemplate.displayName
            } else {
                $fileName = ($notificationTemplate.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $notificationTemplate | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Notification Templates\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Notification Template"
                "Name"   = $notificationTemplate.displayName
                "Path"   = "Notification Templates\$fileName.json"
            }
        }
    }
}
