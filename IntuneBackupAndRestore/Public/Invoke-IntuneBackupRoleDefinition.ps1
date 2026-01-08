function Invoke-IntuneBackupRoleDefinition {
    <#
    .SYNOPSIS
    Backup Intune Role Definitions

    .DESCRIPTION
    Backup Intune Role Definitions as JSON files per role to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupRoleDefinition -Path "C:\temp"
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

    # Get all Role Definitions
    $roleDefinitions = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/roleDefinitions" | Get-MGGraphAllPages

    if ($roleDefinitions -and $roleDefinitions.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Role Definitions")) {
            $null = New-Item -Path "$Path\Role Definitions" -ItemType Directory
        }

        foreach ($roleDefinition in $roleDefinitions) {
            # Skip if displayName is null or empty
            if ([string]::IsNullOrEmpty($roleDefinition.displayName)) {
                Write-Warning "Skipping Role Definition with null or empty displayName (ID: $($roleDefinition.id))"
                continue
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $roleDefinition.displayName
            } else {
                $fileName = ($roleDefinition.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $roleDefinition | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Role Definitions\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Role Definition"
                "Name"   = $roleDefinition.displayName
                "Path"   = "Role Definitions\$fileName.json"
            }
        }
    }
}
