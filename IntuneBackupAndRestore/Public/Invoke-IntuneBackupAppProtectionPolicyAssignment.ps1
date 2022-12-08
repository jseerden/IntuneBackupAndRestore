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
        switch ($appProtectionPolicy.'@odata.type') {
            "#microsoft.graph.androidManagedAppProtection" {
                $dataType = "androidManagedAppProtections"
                break
            }
            "#microsoft.graph.iosManagedAppProtection" {
                $dataType = "iosManagedAppProtections"
                break
            }
            "#microsoft.graph.mdmWindowsInformationProtectionPolicy" {
                $dataType = "mdmWindowsInformationProtectionPolicies"
                break
            }
            "#microsoft.graph.windowsInformationProtectionPolicy" {
                $dataType = "windowsInformationProtectionPolicies"
                break
            }
            "#microsoft.graph.targetedManagedAppConfiguration" {
                $dataType = "targetedManagedAppConfigurations"
                break
            }
            Default {
                continue
            }
        }
        $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceAppManagement/$dataType('$($appProtectionPolicy.id)')/assignments"

        $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\Assignments\$($appProtectionPolicy.id) - $fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Protection Policy Assignments"
            "Name"   = $appProtectionPolicy.displayName
            "Path"   = "App Protection Policies\Assignments\$fileName.json"
        }
    }
}
