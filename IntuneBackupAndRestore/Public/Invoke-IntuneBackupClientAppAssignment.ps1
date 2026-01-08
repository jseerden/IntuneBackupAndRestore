function Invoke-IntuneBackupClientAppAssignment {
    <#
    .SYNOPSIS
    Backup Intune Client App Assignments
    
    .DESCRIPTION
    Backup Intune Client App  Assignments as JSON files per Client App to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientAppAssignment -Path "C:\temp"
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

     # Get all Client Apps
     $filter = "microsoft.graph.managedApp/appAvailability eq null or microsoft.graph.managedApp/appAvailability eq 'lineOfBusiness' or isAssigned eq true"
     $clientApps = Invoke-MgRestMethod -Uri "$apiversion/deviceAppManagement/mobileApps?filter=$filter" | Get-MgGraphAllPages

	if ($clientApps -and $clientApps.Count -gt 0) {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Client Apps\Assignments")) {
			$null = New-Item -Path "$Path\Client Apps\Assignments" -ItemType Directory
		}
	
		foreach ($clientApp in $clientApps) {
			$assignments = (Invoke-MgRestMethod -Uri "/$apiversion/deviceAppManagement/mobileApps/$($clientApp.id)/assignments").value
			if ($assignments) {
				$fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
				$assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Client Apps\Assignments\$($clientApp.id) - $fileName.json"
	
				[PSCustomObject]@{
					"Action" = "Backup"
					"Type"   = "Client App Assignments"
					"Name"   = $clientApp.displayName
					"Path"   = "Client Apps\Assignments\$fileName.json"
				}
			}
		}
	}
}