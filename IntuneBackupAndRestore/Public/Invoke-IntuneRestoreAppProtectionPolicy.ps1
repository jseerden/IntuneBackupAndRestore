function Invoke-IntuneRestoreAppProtectionPolicy {
    <#
    .SYNOPSIS
    Restore Intune App Protection Policy
    
    .DESCRIPTION
    Restore Intune App Protection Policies from JSON files per App Protection Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppProtectionPolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreAppProtectionPolicy -Path "C:\temp" -RestoreById $true
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

    # Get all App Protection Policies
    $appProtectionPolicies = Get-ChildItem -Path "$path\App Protection Policies" -File -ErrorAction SilentlyContinue
    
    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        $appProtectionPolicyContent = Get-Content -LiteralPath $appProtectionPolicy.FullName | convertfrom-json
        $appProtectionPolicyDisplayName = $appProtectionPolicyContent.displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $appProtectionPolicyContent
        # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
        if ($requestBodyObject.supportsScopeTags) {
            $requestBodyObject.supportsScopeTags = $false
        }

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100

        # Restore the App Protection Policy
        try {
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri "$ApiVersion/deviceAppManagement/managedAppPolicies" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Protection Policy"
                "Name"   = $appProtectionPolicyDisplayName
                "Path"   = "App Protection Policies\$($appProtectionPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$appProtectionPolicyDisplayName - Failed to restore App Protection Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
