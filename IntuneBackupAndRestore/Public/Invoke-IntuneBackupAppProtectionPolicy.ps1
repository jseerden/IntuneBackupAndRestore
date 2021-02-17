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
    $AppProtectionPolicies = Get-IntuneAppProtectionPolicy | Get-MSGraphAllPages

    foreach ($AppProtectionPolicy in $AppProtectionPolicies) {
        Write-Output "Backing Up - App Protection Policy: $($AppProtectionPolicy.displayName)"
        $fileName = ($AppProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $AppProtectionPolicy | ConvertTo-Json | Out-File -LiteralPath "$path\App Protection Policies\$fileName.json"
    }
}
