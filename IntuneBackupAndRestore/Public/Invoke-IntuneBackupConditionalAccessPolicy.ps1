function Invoke-IntuneBackupConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Backup Conditional Access Policies

    .DESCRIPTION
    Backup Conditional Access Policies as JSON files per policy to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneBackupConditionalAccessPolicy -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "v1.0"
    )

    # Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "Policy.Read.All"
    }

    # Get all Conditional Access Policies
    $conditionalAccessPolicies = Invoke-MgGraphRequest -Uri "$ApiVersion/identity/conditionalAccess/policies" | Get-MGGraphAllPages

    if ($conditionalAccessPolicies -and $conditionalAccessPolicies.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Conditional Access")) {
            $null = New-Item -Path "$Path\Conditional Access" -ItemType Directory
        }

        foreach ($conditionalAccessPolicy in $conditionalAccessPolicies) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $conditionalAccessPolicy.displayName
            } else {
                $fileName = ($conditionalAccessPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $conditionalAccessPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Conditional Access\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Conditional Access Policy"
                "Name"   = $conditionalAccessPolicy.displayName
                "Path"   = "Conditional Access\$fileName.json"
            }
        }
    }
}
