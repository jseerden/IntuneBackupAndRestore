function Invoke-IntuneBackupNamedLocation {
    <#
    .SYNOPSIS
    Backup Named Locations

    .DESCRIPTION
    Backup Named Locations (IP and Country-based) as JSON files per location to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneBackupNamedLocation -Path "C:\temp"
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

    # Get all Named Locations
    $namedLocations = Invoke-MgGraphRequest -Uri "$ApiVersion/identity/conditionalAccess/namedLocations" | Get-MGGraphAllPages

    if ($namedLocations -and $namedLocations.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Named Locations")) {
            $null = New-Item -Path "$Path\Named Locations" -ItemType Directory
        }

        foreach ($namedLocation in $namedLocations) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $namedLocation.displayName
            } else {
                $fileName = ($namedLocation.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $namedLocation | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Named Locations\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Named Location"
                "Name"   = $namedLocation.displayName
                "Path"   = "Named Locations\$fileName.json"
            }
        }
    }
}
