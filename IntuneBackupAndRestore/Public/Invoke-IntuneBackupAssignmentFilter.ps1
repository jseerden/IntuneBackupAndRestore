function Invoke-IntuneBackupAssignmentFilter {
    <#
    .SYNOPSIS
    Backup Intune Assignment Filters

    .DESCRIPTION
    Backup Intune Assignment Filters as JSON files per filter to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupAssignmentFilter -Path "C:\temp"
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

    # Get all Assignment Filters
    $assignmentFilters = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/assignmentFilters" | Get-MGGraphAllPages

    if ($assignmentFilters -and $assignmentFilters.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Assignment Filters")) {
            $null = New-Item -Path "$Path\Assignment Filters" -ItemType Directory
        }

        foreach ($assignmentFilter in $assignmentFilters) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $assignmentFilter.displayName
            } else {
                $fileName = ($assignmentFilter.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $assignmentFilter | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Assignment Filters\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Assignment Filter"
                "Name"   = $assignmentFilter.displayName
                "Path"   = "Assignment Filters\$fileName.json"
            }
        }
    }
}
