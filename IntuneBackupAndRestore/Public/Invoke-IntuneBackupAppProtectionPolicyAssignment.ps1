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
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    if (-not (Test-Path "$Path\App Protection Policies\Assignments")) {
        $null = New-Item -Path "$Path\App Protection Policies\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $appProtectionPolicies = Get-IntuneAppProtectionPolicy | Get-MSGraphAllPages

    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        # If Android
        if ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection') {
            $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/androidManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
            if ($assignments) {
                Write-Output "Backing Up - Android App Protection Policy - Assignments: $($appProtectionPolicy.displayName)"
            }
        }
        # Elseif iOS
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection') {
            $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/iosManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
            if ($assignments) {
                Write-Output "Backing Up - iOS App Protection Policy - Assignments: $($appProtectionPolicy.displayName)"
            }
        }
        # Elseif Windows 10 with enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
            $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/mdmWindowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
            if ($assignments) {
                Write-Output "Backing Up - Windows 10 (MDM) App Protection Policy - Assignments: $($appProtectionPolicy.displayName)"
            }
        }
        # Elseif Windows 10 without enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
            $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/windowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
            if ($assignments) {
                Write-Output "Backing Up - Windows 10 (WE) App Protection Policy - Assignments: $($appProtectionPolicy.displayName)"
            }
        }
        else {
            # Not supported App Protection Policy
            continue
        }

        $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\Assignments\$($appProtectionPolicy.id) - $fileName.json"
    }
}
