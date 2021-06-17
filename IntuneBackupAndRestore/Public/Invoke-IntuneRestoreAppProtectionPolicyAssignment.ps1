function Invoke-IntuneRestoreAppProtectionPolicyAssignment {
    <#
    .SYNOPSIS
    Restore App Protection Policy Assignments (excluding managedAndroidStoreApp and managedIOSStoreApp)
    
    .DESCRIPTION
    Restore App Protection Policy Assignments from JSON files per App Protection Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppProtectionPolicyAssignment function

    .PARAMETER RestoreById
    If RestoreById is set to false, assignments will be restored to App Protection Policies that match the file name.
    This is necessary if the App Protection Policy was restored from backup, because then a new App Protection Policy is created with a new unique ID.
    
    .EXAMPLE
    Invoke-IntuneRestoreAppProtectionPolicyAssignment -Path "C:\temp" -RestoreById $true
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

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all policies with assignments
    $appProtectionPolicies = Get-ChildItem -Path "$Path\App Protection Policies\Assignments"
    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        $appProtectionPolicyAssignments = Get-Content -LiteralPath $appProtectionPolicy.FullName | ConvertFrom-Json
        $appProtectionPolicyId = ($appProtectionPolicy.BaseName -split " - ")[0]
        $appProtectionPolicyName = ($appProtectionPolicy.BaseName -split " - ",2)[-1]

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($appProtectionPolicyAssignment in $appProtectionPolicyAssignments.Value) {
            $requestBody.assignments += @{
                "target"   = $appProtectionPolicyAssignment.target | Select-Object -Property * -ExcludeProperty deviceAndAppManagementAssignmentFilterId, deviceAndAppManagementAssignmentFilterType
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Get the App Protection Policy we are restoring the assignments for
        try {
            if ($restoreById) {
                $appProtectionPolicyObject = Get-IntuneAppProtectionPolicy -managedAppPolicyId $appProtectionPolicyId
            }
            else {
                $appProtectionPolicyObject = Get-IntuneAppProtectionPolicy | Get-MSGraphAllPages | Where-Object { $_.displayName -eq $appProtectionPolicyName }
                if (-not ($appProtectionPolicyObject)) {
                    Write-Warning "Error retrieving App Protection Policy for $appProtectionPolicyName. Skipping assignment restore"
                    continue
                }
            }
        }
        catch {
            Write-Verbose "Error retrieving App Protection Policy for $appProtectionPolicyName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Restore the assignments
        try {
            # If Android
            if ($appProtectionPolicyObject.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection') {
                $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/androidManagedAppProtections/$($appProtectionPolicyObject.id)/assign" -ErrorAction Stop
            }
            # Elseif iOS
            elseif ($appProtectionPolicyObject.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection') {
                $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/iosManagedAppProtections/$($appProtectionPolicyObject.id)/assign" -ErrorAction Stop
            }
            # Elseif Windows 10 with enrollment
            elseif ($appProtectionPolicyObject.'@odata.type' -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
                $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/mdmWindowsInformationProtectionPolicies/$($appProtectionPolicyObject.id)/assign" -ErrorAction Stop
            }
            # Elseif Windows 10 without Enrollment
            elseif ($appProtectionPolicyObject.'@odata.type' -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
                $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/windowsInformationProtectionPolicies/$($appProtectionPolicyObject.id)/assign" -ErrorAction Stop
            }

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Protection Policy Assignments"
                "Name"   = $appProtectionPolicyName
                "Path"   = "App Protection Policies\Assignments\$($appProtectionPolicy.Name)"
            }
        }
        catch {
            if ($_.Exception.Message -match "The App Protection Policy Assignment already exist") {
                Write-Verbose "$($appProtectionPolicyObject.displayName) - The App Protection Policy Assignment already exists" -Verbose
            }
            else {
                Write-Verbose "$($appProtectionPolicyObject.displayName) - Failed to restore App Protection Policy Assignment(s)" -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}