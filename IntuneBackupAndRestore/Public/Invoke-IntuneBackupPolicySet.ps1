function Invoke-IntuneBackupPolicySet {
    <#
    .SYNOPSIS
    Backup Intune Policy Sets

    .DESCRIPTION
    Backup Intune Policy Sets as JSON files per policy set to the specified Path.
    Policy Sets are collections of policies grouped together for easier management.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupPolicySet -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"
    }

    # Get all Policy Sets (without expand - not supported by API)
    $policySets = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceAppManagement/policySets" | Get-MGGraphAllPages

    if ($policySets -and $policySets.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Policy Sets")) {
            $null = New-Item -Path "$Path\Policy Sets" -ItemType Directory
        }

        foreach ($policySet in $policySets) {
            # Skip if displayName is null or empty
            if ([string]::IsNullOrEmpty($policySet.displayName)) {
                Write-Warning "Skipping Policy Set with null or empty displayName (ID: $($policySet.id))"
                continue
            }

            # Fetch items for this policy set separately (expand not supported on collection query)
            try {
                $policySetWithItems = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceAppManagement/policySets/$($policySet.id)?`$expand=items" -ErrorAction Stop
                $policySet = $policySetWithItems
            } catch {
                Write-Verbose "Could not expand items for Policy Set '$($policySet.displayName)' - backing up without items" -Verbose
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $policySet.displayName
            } else {
                $fileName = ($policySet.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $policySet | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Policy Sets\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Policy Set"
                "Name"   = $policySet.displayName
                "Path"   = "Policy Sets\$fileName.json"
            }
        }
    }
}
