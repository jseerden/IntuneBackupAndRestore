function Invoke-IntuneBackupDeviceHealthScriptAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Health Script Assignments
    
    .DESCRIPTION
    Backup Intune Device Health Script Assignments as JSON files per Device Health Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceHealthScriptAssignment -Path "C:\temp"
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
    $healthScripts = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts" | Get-MGGraphAllPages

	if ($healthScripts -and $healthScripts.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Device Health Scripts\Assignments")) {
			$null = New-Item -Path "$Path\Device Health Scripts\Assignments" -ItemType Directory
		}
	
		foreach ($deviceHealthScript in $healthScripts) {
			$assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$($deviceHealthScript.id)/assignments" | Get-MGGraphAllPages
			
			if ($assignments) {
				$fileName = ($deviceHealthScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
				$assignments | ConvertTo-Json -depth 100 | Out-File -LiteralPath "$path\Device Health Scripts\Assignments\$fileName.json"
	
				[PSCustomObject]@{
					"Action" = "Backup"
					"Type"   = "Device Health Scripts Assignments"
					"Name"   = $deviceHealthScript.displayName
					"Path"   = "Device Health Scripts\Assignments\$fileName.json"
				}
			}
		}
	}
}
