function Invoke-IntuneBackupAppProtectionPolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune App Protection Policy Assignments
    
    .DESCRIPTION
    Backup Intune App Protection Policy Assignments as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupAppProtectionPolicyAssignment -Path "C:\temp"
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
    Select-MgProfile -Name $ApiVersion
    $url = "https://graph.microsoft.com/$ApiVersion"

    # Create folder if not exists
    if (-not (Test-Path "$Path\App Protection Policies\Assignments")) {
        $null = New-Item -Path "$Path\App Protection Policies\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    #$appProtectionPolicies = Get-IntuneAppProtectionPolicy | Get-MSGraphAllPages
    $appProtectionPolicies = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/managedAppPolicies" -OutputType JSON | ConvertFrom-Json
    $appProtectionPolicies = $AppProtectionPolicies.value

    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        # If Android
        if ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection') {
            $assignments = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/androidManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
        }
        # Elseif iOS
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection') {
            $assignments = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/iosManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
        }
        # Elseif Windows 10 with enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
            $assignments = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/mdmWindowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
        }
        # Elseif Windows 10 without enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
            $assignments = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/windowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
        }
        else {
            # Not supported App Protection Policy
            continue
        }
        
        $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments = $assignments.value
        if ($assignments) {
            $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\Assignments\$($appProtectionPolicy.id) - $fileName.json"
            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "App Protection Policy Assignments"
                "Name"   = $appProtectionPolicy.displayName
                "Path"   = "App Protection Policies\Assignments\$fileName.json"
            }
        }
    }
}