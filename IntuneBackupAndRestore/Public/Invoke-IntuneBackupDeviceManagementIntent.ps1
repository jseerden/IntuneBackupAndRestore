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

    #Connect to MS-Graph if required
    if($null -eq (Get-MgContext)){
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All"
    }

    Write-Verbose "Requesting Intents"
    $intents = Get-MgBetaDeviceManagementIntent -all

	if ($intents -and $intents.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Management Intents")) {
			$null = New-Item -Path "$Path\Device Management Intents" -ItemType Directory
		}
	
		foreach ($intent in $intents) {
			# Get the corresponding Device Management Template
			Write-Verbose "Requesting Template"
			$template = Get-MgBetaDeviceManagementTemplate -DeviceManagementTemplateId $($intent.templateId) 
			$templateDisplayName = ($template.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
	
			if (-not (Test-Path "$Path\Device Management Intents\$templateDisplayName")) {
				$null = New-Item -Path "$Path\Device Management Intents\$templateDisplayName" -ItemType Directory
			}
			
			# Get all setting categories in the Device Management Template
			Write-Verbose "Requesting Template Categories"
			$templateCategories = Get-MgBetaDeviceManagementTemplateCategory -DeviceManagementTemplateId $($intent.templateId) -all 
	
			$intentSettingsDelta = @()
			foreach ($templateCategory in $templateCategories) {
				# Get all configured values for the template categories
				Write-Verbose "Requesting Intent Setting Values"
				$intentSettingsDelta += Get-MgBetaDeviceManagementIntentCategorySetting -DeviceManagementIntentId: $($intent.id) -DeviceManagementIntentSettingCategoryId $($templateCategory.id) -all| ForEach-Object{
					[PSCustomObject]@{
						"@odata.type"   = $_.AdditionalProperties."@odata.type"
						id              = $_.id
						definitionId    = $_.DefinitionId
						valueJson       = $_.ValueJson
						value           = $_.AdditionalProperties.value
					}
				}
			}
	
			$intentBackupValue = @{
				"displayName" = $intent.displayName
				"description" = $intent.description
				"settingsDelta" = $intentSettingsDelta
				"roleScopeTagIds" = $intent.roleScopeTagIds
			}
			
			$fileName = ("$($template.id)_$($intent.displayName)").Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$intentBackupValue | ConvertTo-Json -depth 10 | Out-File -LiteralPath "$path\Device Management Intents\$templateDisplayName\$fileName.json"
	
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Device Management Intent"
				"Name"   = $intent.displayName
				"Path"   = "Device Management Intents\$templateDisplayName\$fileName.json"
			}
		}
	}
}
