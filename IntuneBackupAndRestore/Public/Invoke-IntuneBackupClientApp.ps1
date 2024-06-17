function Invoke-IntuneBackupClientApp {
    <#
    .SYNOPSIS
    Backup Intune Client Apps
    
    .DESCRIPTION
    Backup Intune Client Apps as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientApp -Path "C:\temp"
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

	if ($clientApps.value -ne "") {

		# Create folder if not exists
		if (-not (Test-Path "$Path\Client Apps")) {
			$null = New-Item -Path "$Path\Client Apps" -ItemType Directory
		}
		
		foreach ($clientApp in $clientApps) {
			$clientAppType = $clientApp.'@odata.type'.split('.')[-1]
		
			$fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
			$clientAppDetails =  Invoke-MgRestMethod -Uri "$apiversion/deviceAppManagement/mobileApps/$($clientApp.id)"
			$clientAppDetails | ConvertTo-Json -depth 3 | Out-File -LiteralPath "$path\Client Apps\$($clientAppType)_$($fileName).json" 
		
			[PSCustomObject]@{
				"Action" = "Backup"
				"Type"   = "Client App"
				"Name"   = $clientApp.displayName
				"Path"   = "Client Apps\$($clientAppType)_$($fileName).json"
			}
		}
	}
}
