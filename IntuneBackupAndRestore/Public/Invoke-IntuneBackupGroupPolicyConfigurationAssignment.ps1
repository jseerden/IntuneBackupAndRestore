function Invoke-IntuneBackupGroupPolicyConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Group Policy Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Group Policy Configuration Assignments as JSON files per Group Policy Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupGroupPolicyConfigurationAssignment -Path "C:\temp"
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
    
    # Get all assignments from all policies
    $groupPolicyConfigurations = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/groupPolicyConfigurations" | Get-MgGraphAllPages

	if ($groupPolicyConfigurations.value -ne "") {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Administrative Templates\Assignments")) {
			$null = New-Item -Path "$Path\Administrative Templates\Assignments" -ItemType Directory
		}
	
		foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
			$assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/assignments" | Get-MgGraphAllPages
			
			if ($assignments) {
				$fileName = ($groupPolicyConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
				$assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Administrative Templates\Assignments\$fileName.json"
	
				[PSCustomObject]@{
					"Action" = "Backup"
					"Type"   = "Administrative Template Assignments"
					"Name"   = $groupPolicyConfiguration.displayName
					"Path"   = "Administrative Templates\Assignments\$fileName.json"
				}
			}
		}
	}
}