function Invoke-IntuneBackupConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune Settings Catalog Policy Assignments
    
    .DESCRIPTION
    Backup Intune Settings Catalog Policy Assignments as JSON files per Settings Catalog Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupConfigurationPolicyAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Settings Catalog\Assignments")) {
        $null = New-Item -Path "$Path\Settings Catalog\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $configurationPolicies = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/configurationPolicies" | Get-MSGraphAllPages

    foreach ($configurationPolicy in $configurationPolicies) {
        $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/configurationPolicies/$($configurationPolicy.id)/assignments" | Get-MSGraphAllPages
        
        if ($assignments) {
            $fileName = ($configurationPolicy.name).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Settings Catalog\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Settings Catalog Assignments"
                "Name"   = $configurationPolicy.name
                "Path"   = "Settings Catalog\Assignments\$fileName.json"
            }
        }
    }
}