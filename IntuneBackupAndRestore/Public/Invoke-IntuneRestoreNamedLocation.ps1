function Invoke-IntuneRestoreNamedLocation {
    <#
    .SYNOPSIS
    Restore Named Locations

    .DESCRIPTION
    Restore Named Locations (IP and Country-based) from JSON files per Named Location from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupNamedLocation function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreNamedLocation -Path "C:\temp"
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

    # Get all Named Locations
    $namedLocations = Get-ChildItem -Path "$Path\Named Locations" -File -ErrorAction SilentlyContinue

    foreach ($namedLocation in $namedLocations) {
        $namedLocationContent = Get-Content -LiteralPath $namedLocation.FullName -Raw | ConvertFrom-Json

        $namedLocationDisplayName = $namedLocationContent.displayName

        # Remove properties that are not available for creating a new named location
        $requestBody = $namedLocationContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, modifiedDateTime

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Named Location
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/identity/conditionalAccess/namedLocations"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Named Location"
                "Name"   = $namedLocationDisplayName
                "Path"   = "Named Locations\$($namedLocation.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$namedLocationDisplayName - Failed to restore Named Location" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
