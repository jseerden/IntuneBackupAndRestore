function Invoke-IntuneRestorePolicySet {
    <#
    .SYNOPSIS
    Restore Intune Policy Sets

    .DESCRIPTION
    Restore Intune Policy Sets (grouped policies) from JSON files per policy set from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupPolicySet function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestorePolicySet -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementConfiguration.ReadWrite.All"
    }

    # Get all Policy Sets
    $policySets = Get-ChildItem -Path "$Path\Policy Sets" -File -ErrorAction SilentlyContinue

    foreach ($policySet in $policySets) {
        $policySetContent = Get-Content -LiteralPath $policySet.FullName -Raw | ConvertFrom-Json

        $policySetDisplayName = $policySetContent.displayName

        # Remove properties that are not available for creating a new policy set
        # Note: items property contains references to policies that need to exist first
        $requestBody = $policySetContent | Select-Object -Property displayName, description

        # Add items if they exist and have valid policy references
        # This is a simplified restore - full item restoration would require mapping old IDs to new IDs
        if ($policySetContent.items -and $policySetContent.items.Count -gt 0) {
            Write-Verbose "$policySetDisplayName - Policy Set contains $($policySetContent.items.Count) items that will need to be added separately" -Verbose
        }

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Policy Set
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceAppManagement/policySets"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Policy Set"
                "Name"   = $policySetDisplayName
                "Path"   = "Policy Sets\$($policySet.Name)"
                "Id"     = $createdPolicy.id
            }
            Write-Verbose "$policySetDisplayName - Policy Set restored successfully. Note: Policy items need to be added manually or through assignment restore." -Verbose
        }
        catch {
            Write-Verbose "$policySetDisplayName - Failed to restore Policy Set" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
