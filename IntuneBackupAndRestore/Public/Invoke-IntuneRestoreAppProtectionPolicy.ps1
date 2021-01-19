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

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Get all App Protection Policies
    $AppProtectionPolicies = Get-ChildItem -Path "$path\App Protection Policies" -File
    
    foreach ($AppProtectionPolicy in $AppProtectionPolicies) {
        $AppProtectionPolicyContent = Get-Content -LiteralPath $AppProtectionPolicy.FullName -Raw
        $AppProtectionPolicyDisplayName = ($AppProtectionPolicyContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $AppProtectionPolicyContent | ConvertFrom-Json
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

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json

        # Restore the App Protection Policy
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/managedAppPolicies" -ErrorAction Stop
            Write-Output "$AppProtectionPolicyDisplayName - Successfully restored App Protection Policy"
        }
        catch {
            Write-Output "$AppProtectionPolicyDisplayName - Failed to restore App Protection Policy"
            Write-Error $_ -ErrorAction Continue
        }
    }
}
