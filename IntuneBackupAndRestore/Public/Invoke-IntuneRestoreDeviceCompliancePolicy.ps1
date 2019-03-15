function Invoke-IntuneRestoreDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Restore Intune Device Compliance Policies
    
    .DESCRIPTION
    Restore Intune Device Compliance Policies from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceCompliancePolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceCompliance -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Get-ChildItem -Path "$Path\Device Compliance Policies" -File
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $deviceCompliancePolicyContent = Get-Content -Path $deviceCompliancePolicy.FullName -Raw

        # Restore the Device Compliance Policy
        try {
            $null = New-GraphDeviceCompliancePolicy -RequestBody $deviceCompliancePolicyContent -ErrorAction Stop
            Write-Output "$($deviceCompliancePolicy.BaseName) - Succesfully restored Device Compliance Policy"
        }
        catch {
            Write-Output "$($deviceCompliancePolicy.BaseName) - Failed to restore Device Compliance Policy"
            Write-Error $_ -ErrorAction Continue
        }
    }
}