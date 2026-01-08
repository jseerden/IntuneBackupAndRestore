function Invoke-IntuneBackupRoleScopeTag {
    <#
    .SYNOPSIS
    Backup Intune Role Scope Tags

    .DESCRIPTION
    Backup Intune Role Scope Tags as JSON files per scope tag to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupRoleScopeTag -Path "C:\temp"
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
        Connect-MgGraph -Scopes "DeviceManagementRBAC.ReadWrite.All"
    }

    # Get all Role Scope Tags
    $roleScopeTags = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/roleScopeTags" | Get-MGGraphAllPages

    if ($roleScopeTags -and $roleScopeTags.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Role Scope Tags")) {
            $null = New-Item -Path "$Path\Role Scope Tags" -ItemType Directory
        }

        foreach ($roleScopeTag in $roleScopeTags) {
            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $roleScopeTag.displayName
            } else {
                $fileName = ($roleScopeTag.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $roleScopeTag | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Role Scope Tags\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Role Scope Tag"
                "Name"   = $roleScopeTag.displayName
                "Path"   = "Role Scope Tags\$fileName.json"
            }
        }
    }
}
