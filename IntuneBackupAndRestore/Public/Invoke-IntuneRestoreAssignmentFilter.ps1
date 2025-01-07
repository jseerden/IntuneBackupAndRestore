function Invoke-IntuneRestoreAssignmentFilter {
    <#
    .SYNOPSIS
    Restore Intune Assignment Filters
    
    .DESCRIPTION
    Restore Intune Assignment Filters from JSON files per Assignment Filter Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAssignmentFilter function
    
    .EXAMPLE
    Invoke-IntuneRestoreAssignmentFilter -Path "C:\temp" -RestoreById $true
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

    # Get all Assignment Filters
    $AssignmentFilters = Get-ChildItem -Path "$path\Assignment Filters" -File
    
    foreach ($AssignmentFilter in $AssignmentFilters) {
        $AssignmentFilterContent = Get-Content -LiteralPath $AssignmentFilter.FullName -Raw
        $AssignmentFilterDisplayName = ($AssignmentFilterContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $AssignmentFilterContent | ConvertFrom-Json
        # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
        #if ($requestBodyObject.supportsScopeTags) {
        #    $requestBodyObject.supportsScopeTags = $false
        #}

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, deviceEnrollmentConfigurationId, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100

        # Restore the Assignment Filter
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/AssignmentFilters" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Assignment Filter"
                "Name"   = $AssignmentFilterDisplayName
                "Path"   = "Assignment Filters\$($AssignmentFilter.Name)"
            }
        }
        catch {
            Write-Verbose "$AssignmentFilterDisplayName - Failed to restore Assignment Filter" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}