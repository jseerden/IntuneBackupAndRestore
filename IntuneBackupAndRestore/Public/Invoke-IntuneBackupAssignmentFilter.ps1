function Invoke-IntuneBackupAssignmentFilter {
    <#
    .SYNOPSIS
    Backup Intune Assignment Filter
    
    .DESCRIPTION
    Backup Intune Assignment filters as JSON files per assignment filter to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
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

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    if (-not (Test-Path "$Path\Assignment Filters")) {
        $null = New-Item -Path "$Path\Assignment Filters" -ItemType Directory
    }

    # Get all App Protection Policies
    $assignmentFilters = Invoke-MSGraphRequest -HttpMethod GET -Url "/deviceManagement/assignmentFilters"| Get-MSGraphAllPages

    foreach ($assignmentFilter in $assignmentFilters) {
        $fileName = ($assignmentFilter.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignmentFilter | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Assignment Filters\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Assignment Filter"
            "Name"   = $assignmentFilter.displayName
            "Path"   = "Assignment Filters\$fileName.json"
        }
    }
}
