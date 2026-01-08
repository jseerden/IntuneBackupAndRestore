function Invoke-IntuneRestoreNotificationTemplate {
    <#
    .SYNOPSIS
    Restore Intune Notification Templates

    .DESCRIPTION
    Restore Intune Notification Templates (for compliance notifications) from JSON files per template from the specified Path.
    Uses a two-step process: 1) Create template, 2) Add localized messages

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupNotificationTemplate function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreNotificationTemplate -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "v1.0"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get all Notification Templates
    $notificationTemplates = Get-ChildItem -Path "$Path\Notification Templates" -File -ErrorAction SilentlyContinue

    foreach ($notificationTemplate in $notificationTemplates) {
        $notificationTemplateContent = Get-Content -LiteralPath $notificationTemplate.FullName -Raw | ConvertFrom-Json

        $notificationTemplateDisplayName = $notificationTemplateContent.displayName

        # Skip default notification templates
        if ($notificationTemplateDisplayName -like "*Default*" -or $notificationTemplateContent.id -match "^0000") {
            Write-Verbose "Skipping built-in Notification Template: $notificationTemplateDisplayName" -Verbose
            continue
        }

        # Save localizedNotificationMessages for later (Step 2)
        $localizedMessages = $notificationTemplateContent.localizedNotificationMessages

        # Step 1: Create the template WITHOUT localizedNotificationMessages
        # Remove properties that cannot be set during creation
        $requestBody = $notificationTemplateContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, modifiedDateTime, supportsScopeTags, 'localizedNotificationMessages@odata.context', localizedNotificationMessages

        # Add @odata.type to ensure proper type
        if (-not $requestBody.'@odata.type') {
            $requestBody | Add-Member -MemberType NoteProperty -Name "@odata.type" -Value "#microsoft.graph.notificationMessageTemplate" -Force
        }

        # Remove defaultLocale if present - it may cause issues during creation
        if ($requestBody.PSObject.Properties.Name -contains 'defaultLocale') {
            $requestBody.PSObject.Properties.Remove('defaultLocale')
            Write-Verbose "$notificationTemplateDisplayName - Removed defaultLocale property" -Verbose
        }

        # Remove description if present - it may cause issues during creation
        if ($requestBody.PSObject.Properties.Name -contains 'description') {
            $requestBody.PSObject.Properties.Remove('description')
            Write-Verbose "$notificationTemplateDisplayName - Removed description property" -Verbose
        }

        # Validate displayName length (max 50 characters for Notification Templates)
        if ($requestBody.displayName.Length -gt 50) {
            Write-Warning "$notificationTemplateDisplayName - Display name exceeds 50 characters, truncating..."
            $requestBody.displayName = $requestBody.displayName.Substring(0, 47) + "..."
        }

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Debug: Log the request body
        Write-Verbose "REQUEST BODY FOR $notificationTemplateDisplayName :" -Verbose
        Write-Verbose $requestBodyJson -Verbose

        # Step 1: Create the Notification Template
        try {
            $createdTemplate = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/notificationMessageTemplates" -ErrorAction Stop
            Write-Verbose "$notificationTemplateDisplayName - Template created successfully (ID: $($createdTemplate.id))" -Verbose

            # Step 2: Add localized notification messages
            if ($localizedMessages -and $localizedMessages.Count -gt 0) {
                Write-Verbose "$notificationTemplateDisplayName - Adding $($localizedMessages.Count) localized message(s)..." -Verbose

                foreach ($message in $localizedMessages) {
                    # Remove read-only properties from localized message
                    $messageBody = $message | Select-Object -Property * -ExcludeProperty id, lastModifiedDateTime, isDefault

                    # Add @odata.type for localized message
                    $messageBody | Add-Member -MemberType NoteProperty -Name "@odata.type" -Value "#microsoft.graph.localizedNotificationMessage" -Force

                    $messageBodyJson = $messageBody | ConvertTo-Json -Depth 10

                    try {
                        $createdMessage = Invoke-MgGraphRequest -Method POST -Body $messageBodyJson.toString() -Uri "$ApiVersion/deviceManagement/notificationMessageTemplates/$($createdTemplate.id)/localizedNotificationMessages" -ErrorAction Stop
                        Write-Verbose "$notificationTemplateDisplayName - Added localized message for locale: $($message.locale)" -Verbose
                    }
                    catch {
                        Write-Warning "$notificationTemplateDisplayName - Failed to add localized message for locale $($message.locale): $($_.Exception.Message)"
                    }
                }
            }

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Notification Template"
                "Name"   = $notificationTemplateDisplayName
                "Path"   = "Notification Templates\$($notificationTemplate.Name)"
                "Id"     = $createdTemplate.id
            }
        }
        catch {
            Write-Verbose "$notificationTemplateDisplayName - Failed to restore Notification Template" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
