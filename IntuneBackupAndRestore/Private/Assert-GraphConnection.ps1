function Assert-GraphConnection {
	<#
	.SYNOPSIS
		Asserts a valid Graph connection has been established.
	
	.DESCRIPTION
		Asserts a valid Graph connection has been established.
	
	.PARAMETER Cmdlet
		The $PSCmdlet variable of the calling command.
	
	.EXAMPLE
		PS C:\> Assert-GraphConnection -Cmdlet $PSCmdlet
	
		Asserts a valid Graph connection has been established.
#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		$Cmdlet
	)
	
	process {
		if ($null -ne (Get-MgContext)) {
			Write-Verbose "MS-Graph already connected, checking scopes"
			$requiredScopes = @(
				"DeviceManagementApps.ReadWrite.All",
				"DeviceManagementConfiguration.ReadWrite.All",
				"DeviceManagementServiceConfig.ReadWrite.All",
				"DeviceManagementManagedDevices.ReadWrite.All",
				"DeviceManagementScripts.ReadWrite.All"
			)
			$connectionScopes = Get-MgContext | Select-Object -ExpandProperty Scopes
			$IncorrectScopes = $false
			foreach($scope in $requiredScopes){
				if($scope -notin $connectionScopes){
					Write-Verbose "'$scope' is not found as a valid scope for current MS-Graph connection"
					$IncorrectScopes = $true
					break
				}
			}

			if (-not $IncorrectScopes) {
				Write-Host "MS-Graph connected and scopes are correct."
				return
			}
		}
		
		$exception = [System.InvalidOperationException]::new('Not yet connected to Graph API or scopes are incorrect. Use Connect-IntuneBackupAndRestore to establish a connection!')
		$errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, "NotConnected", 'InvalidOperation', $null)
		
		$Cmdlet.ThrowTerminatingError($errorRecord)
	}
}