function Test-GraphConnection {
    <#
    .SYNOPSIS
	Tests the connection to Microsoft Graph.

    .DESCRIPTION
	Checks that a connection is already established with Microsoft Graph (using Connect-MgGraph from the Microsoft Graph PowerShell SDK) and that the required scopes are included in the connection.
	If no connection is established, or if the required scopes are not included, it will prompt the user to connect to Microsoft Graph with the correct scopes.

    .PARAMETER RequiredScopes
	An array of the required scopes for the current operation.

	.PARAMETER CheckScopes
	Switch parameter, indicating whether the current operation requires first checking that the required scopes are active in the current connection.

    .EXAMPLE
	PS C:\> Test-GraphConnection -RequiredScopes "DeviceManagementApps.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All"

	First checks if there is already a connection established with Microsoft Graph, and if not then initializes the connection with the listed scopes.

    .EXAMPLE
	PS C:\> Test-GraphConnection -RequiredScopes "DeviceManagementApps.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All" -CheckScopes

	First checks if there is already a connection established with Microsoft Graph.
	If there isn't a connection, then it initializes the connection process with the listed scopes.
	If there *is* a connection already present, then it will check that the listed scopes are active, and re-run the connection process if there is one or more missing.
    #>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory)]
		[string[]]$RequiredScopes,

		[switch]$CheckScopes
	)

    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -scopes $RequiredScopes
    } elseif ($CheckScopes) {
        Write-Host "MS-Graph already connected, checking scopes"
        $currentScopes = Get-MgContext | Select-Object -ExpandProperty Scopes
		$missingScopes = Compare-Object -ReferenceObject $RequiredScopes -DifferenceObject $currentScopes |
			Where-Object { $_.SideIndicator -eq '<=' }
		if ($missingScopes) {
            Write-Host "Incorrect scopes, please sign in again"
            Connect-MgGraph -scopes $RequiredScopes
		} else {
			Write-Host "MS-Graph scopes are correct"
		}
		Write-Host ""
    }
}
