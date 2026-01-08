function Invoke-IntuneBackupDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Backup Intune Device Compliance Policies
    
    .DESCRIPTION
    Backup Intune Device Compliance Policies as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceCompliancePolicy -Path "C:\temp"
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
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All" 
    }

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceCompliancePolicies" | Get-MGGraphAllPages

	if ($deviceCompliancePolicies -and $deviceCompliancePolicies.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Compliance Policies")) {
			$null = New-Item -Path "$Path\Device Compliance Policies" -ItemType Directory
		}
		
		foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
			$fileName = ($deviceCompliancePolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$deviceCompliancePolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Compliance Policies\$fileName.json"
	
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Device Compliance Policy"
				"Name"   = $deviceCompliancePolicy.displayName
				"Path"   = "Device Compliance Policies\$fileName.json"
			}
		}
	}
}