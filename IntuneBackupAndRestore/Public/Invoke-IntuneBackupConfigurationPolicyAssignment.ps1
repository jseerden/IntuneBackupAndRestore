function Invoke-IntuneBackupConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune Settings Catalog Policy Assignments
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policy Assignments as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path "C:\temp"
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

    # Get all assignments from all policies
    $configurationPolicies = (Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/configurationPolicies") | Get-MGGraphAllPages

	if ($configurationPolicies -and $configurationPolicies.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Settings Catalog\Assignments")) {
			$null = New-Item -Path "$Path\Settings Catalog\Assignments" -ItemType Directory
		}
	
		foreach ($configurationPolicy in $configurationPolicies) {
			$assignments = (Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/configurationPolicies/$($configurationPolicy.id)/assignments") | Get-MGGraphAllPages
			if ($assignments) {
				$fileName = ($configurationPolicy.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
				$assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Settings Catalog\Assignments\$fileName.json"
	
				[PSCustomObject]@{
					"Action" = "Backup"
					"Type"   = "Settings Catalog Assignments"
					"Name"   = $configurationPolicy.name
					"Path"   = "Settings Catalog\Assignments\$fileName.json"
				}
			}
		}
	}
}