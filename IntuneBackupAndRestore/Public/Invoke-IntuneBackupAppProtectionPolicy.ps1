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
    Select-MgProfile -Name $ApiVersion
    $url = "https://graph.microsoft.com/$ApiVersion"

    # Create folder if not exists
    if (-not (Test-Path "$Path\App Protection Policies")) {
        $null = New-Item -Path "$Path\App Protection Policies" -ItemType Directory
    }

    # Get all App Protection Policies
    $appProtectionPolicies = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/managedAppPolicies" -OutputType JSON | ConvertFrom-Json
    $appProtectionPolicies = $AppProtectionPolicies.value

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