function Invoke-IntuneRestoreAssignmentFilter {
    <#
    .SYNOPSIS
    Restore Intune Assignment Filters

    .DESCRIPTION
    Restore Intune Assignment Filters from JSON files per Assignment Filter from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAssignmentFilter function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreAssignmentFilter -Path "C:\temp"
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

    # Get all Assignment Filters
    $assignmentFilters = Get-ChildItem -Path "$Path\Assignment Filters" -File -ErrorAction SilentlyContinue

    foreach ($assignmentFilter in $assignmentFilters) {
        $assignmentFilterContent = Get-Content -LiteralPath $assignmentFilter.FullName -Raw | ConvertFrom-Json

        $assignmentFilterDisplayName = $assignmentFilterContent.displayName

        # Remove properties that are not available for creating a new assignment filter
        $requestBody = $assignmentFilterContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, payloads

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Assignment Filter
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/assignmentFilters"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Assignment Filter"
                "Name"   = $assignmentFilterDisplayName
                "Path"   = "Assignment Filters\$($assignmentFilter.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$assignmentFilterDisplayName - Failed to restore Assignment Filter" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
