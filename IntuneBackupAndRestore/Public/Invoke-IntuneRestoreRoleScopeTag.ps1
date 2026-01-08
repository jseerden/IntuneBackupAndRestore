function Invoke-IntuneRestoreRoleScopeTag {
    <#
    .SYNOPSIS
    Restore Intune Role Scope Tags

    .DESCRIPTION
    Restore Intune Role Scope Tags from JSON files per Role Scope Tag from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupRoleScopeTag function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneRestoreRoleScopeTag -Path "C:\temp"
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
        connect-mggraph -scopes "DeviceManagementRBAC.ReadWrite.All"
    }

    # Get all Role Scope Tags
    $roleScopeTags = Get-ChildItem -Path "$Path\Role Scope Tags" -File -ErrorAction SilentlyContinue

    foreach ($roleScopeTag in $roleScopeTags) {
        $roleScopeTagContent = Get-Content -LiteralPath $roleScopeTag.FullName -Raw | ConvertFrom-Json

        $roleScopeTagDisplayName = $roleScopeTagContent.displayName

        # Skip the default role scope tags (0 and 1)
        if ($roleScopeTagContent.id -eq "0" -or $roleScopeTagContent.displayName -eq "Default") {
            Write-Verbose "Skipping built-in Role Scope Tag: $roleScopeTagDisplayName" -Verbose
            continue
        }

        # Remove properties that are not available for creating a new role scope tag
        $requestBody = $roleScopeTagContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Role Scope Tag
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/roleScopeTags"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Role Scope Tag"
                "Name"   = $roleScopeTagDisplayName
                "Path"   = "Role Scope Tags\$($roleScopeTag.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$roleScopeTagDisplayName - Failed to restore Role Scope Tag" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
