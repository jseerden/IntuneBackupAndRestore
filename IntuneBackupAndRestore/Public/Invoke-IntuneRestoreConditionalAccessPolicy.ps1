function Invoke-IntuneRestoreConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Restore Conditional Access Policies

    .DESCRIPTION
    Restore Conditional Access Policies from JSON files per policy from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupConditionalAccessPolicy function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreConditionalAccessPolicy -Path "C:\temp"
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
        connect-mggraph -scopes "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess"
    }

    # Get all Conditional Access Policies
    $conditionalAccessPolicies = Get-ChildItem -Path "$Path\Conditional Access" -File -ErrorAction SilentlyContinue

    foreach ($conditionalAccessPolicy in $conditionalAccessPolicies) {
        $conditionalAccessPolicyContent = Get-Content -LiteralPath $conditionalAccessPolicy.FullName -Raw | ConvertFrom-Json

        $conditionalAccessPolicyDisplayName = $conditionalAccessPolicyContent.displayName

        # Remove properties that are not available for creating a new policy
        $requestBody = $conditionalAccessPolicyContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, modifiedDateTime

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Conditional Access Policy
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/identity/conditionalAccess/policies"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Conditional Access Policy"
                "Name"   = $conditionalAccessPolicyDisplayName
                "Path"   = "Conditional Access\$($conditionalAccessPolicy.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$conditionalAccessPolicyDisplayName - Failed to restore Conditional Access Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
