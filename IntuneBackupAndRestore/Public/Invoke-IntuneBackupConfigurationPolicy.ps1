function Invoke-IntuneBackupConfigurationPolicy {
    <#
    .SYNOPSIS
    Backup Intune Settings Catalog Policies
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policies as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicy -Path "C:\temp"
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

    # Get all Setting Catalogs Policies
    $configurationPolicies = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/configurationPolicies" | Get-MGGraphAllPages

	if ($configurationPolicies -and $configurationPolicies.Count -gt 0) {

	    # Create folder if not exists
		if (-not (Test-Path "$Path\Settings Catalog")) {
			$null = New-Item -Path "$Path\Settings Catalog" -ItemType Directory
		}

		foreach ($configurationPolicy in $configurationPolicies) {
			$configurationPolicy | Add-Member -MemberType NoteProperty -Name 'settings' -Value @() -Force
			$settings = (Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/configurationPolicies/$($configurationPolicy.id)/settings").value
	
			if ($settings -isnot [System.Array]) {
				$configurationPolicy.Settings = @($settings)
			} else {
				$configurationPolicy.Settings = $settings
			}
			
			$fileName = ($configurationPolicy.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$configurationPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Settings Catalog\$fileName.json"
	
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Settings Catalog"
				"Name"   = $configurationPolicy.name
				"Path"   = "Settings Catalog\$fileName.json"
			}
		}
	}
}
