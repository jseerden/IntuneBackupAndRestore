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
        [bool]$RestoreById = $false,

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
    $appProtectionPolicies = Get-ChildItem -Path "$path\App Protection Policies" -File
    
    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        $appProtectionPolicyContent = Get-Content -LiteralPath $appProtectionPolicy.FullName -Raw
        $appProtectionPolicyDisplayName = ($appProtectionPolicyContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $appProtectionPolicyContent | ConvertFrom-Json
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
            if($RestoreById)
            { $null = Invoke-MSGraphRequest -HttpMethod PUT -Content $requestBody.toString() -Url "deviceManagement/managedAppPolicies/$($appProtectionPolicyContent.id)" -ErrorAction Stop }
            else 
            { $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/managedAppPolicies" -ErrorAction Stop }
            
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
