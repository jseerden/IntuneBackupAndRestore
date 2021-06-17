function Invoke-IntuneBackupAppProtectionPolicy {
    <#
    .SYNOPSIS
    Backup Intune App Protection Policy
    
    .DESCRIPTION
    Backup Intune App Protection Policies as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupAppProtectionPolicy -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Protection Policies")) {
        $null = New-Item -Path "$Path\App Protection Policies" -ItemType Directory
    }

    # Get all App Protection Policies
    $appProtectionPolicies = Get-IntuneAppProtectionPolicy | Get-MSGraphAllPages

    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $appProtectionPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Protection Policy"
            "Name"   = $appProtectionPolicy.displayName
            "Path"   = "App Protection Policies\$fileName.json"
        }
    }
}
