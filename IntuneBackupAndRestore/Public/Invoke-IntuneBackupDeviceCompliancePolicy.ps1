function Invoke-IntuneBackupDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Backup Intune Device Compliance Policies
    
    .DESCRIPTION
    Backup Intune Device Compliance Policies as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceCompliancePolicy -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Compliance Policies")) {
        $null = New-Item -Path "$Path\Device Compliance Policies" -ItemType Directory
    }

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Get-GraphDeviceCompliancePolicy

    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        Write-Output "Backing Up - Device Compliance Policy: $($deviceCompliancePolicy.displayName)"
        $fileName = ($deviceCompliancePolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $deviceCompliancePolicy | ConvertTo-Json | Out-File -LiteralPath "$path\Device Compliance Policies\$fileName.json"
    }
}