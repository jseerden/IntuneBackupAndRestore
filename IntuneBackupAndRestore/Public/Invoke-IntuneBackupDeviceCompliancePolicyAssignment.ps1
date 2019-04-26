function Invoke-IntuneBackupDeviceCompliancePolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Complaince Policy Assignments
    
    .DESCRIPTION
    Backup Intune Device Complaince Policy Assignments as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceCompliancePolicyAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Compliance Policies\Assignments")) {
        $null = New-Item -Path "$Path\Device Compliance Policies\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $deviceCompliancePolicies = Get-GraphDeviceCompliancePolicy

    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $assignments = Get-GraphDeviceCompliancePolicyAssignment -Id $deviceCompliancePolicy.id 
        if ($assignments) {
            Write-Output "Backing Up - Device Compliance Policy - Assignments: $($deviceCompliancePolicy.displayName)"
            $fileName = ($deviceCompliancePolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Compliance Policies\Assignments\$fileName.json"
        }
    }
}