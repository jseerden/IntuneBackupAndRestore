function Invoke-IntuneBackupGroupPolicyConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Group Policy Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Group Policy Configuration Assignments as JSON files per Group Policy Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupGroupPolicyConfigurationAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Administrative Templates\Assignments")) {
        $null = New-Item -Path "$Path\Administrative Templates\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $groupPolicyConfigurations = Get-GraphGroupPolicyConfiguration

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $assignments = Get-GraphGroupPolicyConfigurationAssignment -Id $groupPolicyConfiguration.id 
        if ($assignments) {
            Write-Output "Backing Up - Administrative Templates - Assignments: $($groupPolicyConfiguration.displayName)"
            $fileName = ($groupPolicyConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Administrative Templates\Assignments\$fileName.json"
        }
    }
}