function Invoke-IntuneBackupAppProtectionPolicy {
    <#
    .SYNOPSIS
    Backup Intune App Protection Policy
    
    .DESCRIPTION
    Backup Intune App Protection Policies as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupAppProtectionPolicy -Path "C:\temp"
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

    # Get all App Protection Policies
    $appProtectionPolicies = Invoke-MgGraphRequest -Uri "/$ApiVersion/deviceAppManagement/managedAppPolicies" | Get-MgGraphAllPages

	if ($appProtectionPolicies -and $appProtectionPolicies.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\App Protection Policies")) {
			$null = New-Item -Path "$Path\App Protection Policies" -ItemType Directory
		}
	
		foreach ($appProtectionPolicy in $appProtectionPolicies) {
	
			if (($appProtectionPolicy.AppGroupType -eq "selectedPublicApps") -and ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection')) {
				$uri = "$ApiVersion/deviceAppManagement/androidManagedAppProtections('$($appProtectionPolicy.id)')"+'?$expand=apps'
				$appProtectionPolicy.apps = (Invoke-MgGraphRequest -method get -Uri $uri).apps
			}
	
			if (($appProtectionPolicy.AppGroupType -eq "selectedPublicApps") -and ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection')) {
				$uri = "$ApiVersion/deviceAppManagement/iosManagedAppProtections('$($appProtectionPolicy.id)')"+'?$expand=apps'
				$appProtectionPolicy.add("apps",(Invoke-MgGraphRequest -method get -Uri $uri).apps) 
			}
	
			# Skip if displayName is null or empty
			if ([string]::IsNullOrEmpty($appProtectionPolicy.displayName)) {
				Write-Warning "Skipping App Protection Policy with null or empty displayName (ID: $($appProtectionPolicy.id))"
				continue
			}

			$fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$appProtectionPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\$fileName.json"
	
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "App Protection Policy"
				"Name"   = $appProtectionPolicy.displayName
				"Path"   = "App Protection Policies\$fileName.json"
			}
		}
	}
}
