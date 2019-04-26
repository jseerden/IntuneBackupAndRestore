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
        [bool]$RestoreById = $true
    )

    # Get all policies with assignments
    $clientApps = Get-ChildItem -Path "$Path\Client Apps\Assignments"
    foreach ($clientApp in $clientApps) {
        $clientAppAssignments = Get-Content -LiteralPath $clientApp.FullName -Raw
        $clientAppId = ($clientApp.BaseName -split " - ")[0]
        $clientAppName = ($clientApp.BaseName -split " - ")[1]

        # Get the Client App we are restoring the assignments for
        try {
            if ($RestoreById) {
                $clientAppObject = Get-GraphClientApp -Id $clientAppId
            }
            else {
                $clientAppObject = Get-GraphClientApp | Where-Object { $_.displayName -eq "$($clientAppName)" -and $_.'@odata.type' -ne "#microsoft.graph.managedAndroidStoreApp" -and $_.'@odata.type' -ne "#microsoft.graph.managedIOSStoreApp" }
                if (-not ($clientAppObject)) {
                    Write-Warning "Error retrieving Intune Client App for $($clientApp.FullName). Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Output "Error retrieving Intune Client App for $($clientApp.FullName), does it exist in the Intune tenant? Skipping assignment restore ..."
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            $null = New-GraphClientAppAssignment -Id $clientAppObject.id -RequestBody $clientAppAssignments -ErrorAction Stop
            Write-Output "$($clientAppObject.displayName) - Successfully restored Client App Assignment(s)"
        }
        catch {
            if ($_.Exception.Message -match "The MobileApp Assignment already exist") {
                Write-Output "$($clientAppObject.displayName) - The Client App Assignment already exists"
            }
            else {
                Write-Output "$($clientAppObject.displayName) - Failed to restore Client App Assignment(s)"
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}