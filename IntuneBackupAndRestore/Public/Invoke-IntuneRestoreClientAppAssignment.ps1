function Invoke-IntuneRestoreClientAppAssignment {
    <#
    .SYNOPSIS
    Restore Intune Client App Assignments (excluding managedAndroidStoreApp and managedIOSStoreApp)
    
    .DESCRIPTION
    Restore Intune Client App Assignments from JSON files per Client App from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupClientAppAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to false, assignments will be restored to Intune Client Apps that match the file name.
    This is necessary if the Client App was restored from backup, because then a new Client App is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreClientAppAssignment -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RestoreById = $true,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Get all policies with assignments
    $clientAppsAssignmentItems = Get-ChildItem -Path "$Path\Client Apps\Assignments" -File -ErrorAction SilentlyContinue
    $clientApps = Get-ChildItem -Path "$Path\Client Apps" -File -ErrorAction SilentlyContinue
	
    foreach ($clientApp in $clientAppsAssignmentItems) {
        $clientAppAssignments = Get-Content -LiteralPath $clientApp.FullName | ConvertFrom-Json
        $clientAppId = ($clientApp.BaseName -split " - ")[0]
        $clientAppName = ($clientApp.BaseName -split " - ",2)[-1]

        # Create the base requestBody
        $requestBody = @{
            mobileAppAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($clientAppAssignment in $clientAppAssignments) {

            $clientAppAssignment.settings.installTimeSettings.PSObject.Properties | Foreach-Object {
                if ($null -ne $_.Value) {
                    if ($_.Value.GetType().Name -eq "DateTime") {
                        $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                    }
                }
            }

            $requestBody.mobileAppAssignments += @{
                "target"   = $clientAppAssignment.target
                "intent"   = $clientAppAssignment.intent
                "settings" = $clientAppAssignment.settings
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the Client App we are restoring the assignments for
        try {
            if ($restoreById) {
                $clientAppObject = Invoke-MgGraphRequest -Uri "$apiversion/deviceAppManagement/mobileApps/$clientAppId" 
            }
            else {
                $clientAppObject = Invoke-MgGraphRequest -Uri "$apiversion/deviceAppManagement/mobileApps/" | Get-MgGraphAllPages | Where-Object { $_.displayName -eq "$($clientAppName)" -and $_.'@odata.type' -ne "#microsoft.graph.managedAndroidStoreApp" -and $_.'@odata.type' -ne "#microsoft.graph.managedIOSStoreApp" }
                if (-not ($clientAppObject)) {
                    Write-Warning "Error retrieving Intune Client App for $($clientApp.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving Intune Client App for $($clientApp.FullName), does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$ApiVersion/deviceAppManagement/mobileApps/$($clientAppObject.id)/assign" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Client App Assignments"
                "Name"   = $clientAppObject.displayName
                "Path"   = "Client Apps\Assignments\$($clientApp.Name)"
            }
        }
        catch {
            if ($_.Exception.Message -match "The MobileApp Assignment already exist") {
                Write-Verbose "$($clientAppObject.displayName) - The Client App Assignment already exists" -Verbose
            }
            else {
                Write-Verbose "$($clientAppObject.displayName) - Failed to restore Client App Assignment(s)" -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}