function Invoke-IntuneRestoreRoleDefinition {
    <#
    .SYNOPSIS
    Restore Intune Role Definitions

    .DESCRIPTION
    Restore Intune Role Definitions (custom RBAC roles) from JSON files per role from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupRoleDefinition function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreRoleDefinition -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "v1.0"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementRBAC.ReadWrite.All"
    }

    # Get all Role Definitions
    $roleDefinitions = Get-ChildItem -Path "$Path\Role Definitions" -File -ErrorAction SilentlyContinue

    foreach ($roleDefinition in $roleDefinitions) {
        $roleDefinitionContent = Get-Content -LiteralPath $roleDefinition.FullName -Raw | ConvertFrom-Json

        $roleDefinitionDisplayName = $roleDefinitionContent.displayName

        # Skip built-in roles (isBuiltIn = true)
        if ($roleDefinitionContent.isBuiltIn -eq $true) {
            Write-Verbose "Skipping built-in Role Definition: $roleDefinitionDisplayName" -Verbose
            continue
        }

        # Remove properties that are not available for creating a new role definition
        $requestBody = $roleDefinitionContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, isBuiltInRoleDefinition

        # Remove 'actions' property from rolePermissions and permissions arrays (read-only computed property)
        if ($requestBody.rolePermissions) {
            foreach ($permission in $requestBody.rolePermissions) {
                $permission.PSObject.Properties.Remove('actions')
            }
        }
        if ($requestBody.permissions) {
            foreach ($permission in $requestBody.permissions) {
                $permission.PSObject.Properties.Remove('actions')
            }
        }

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Role Definition
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/roleDefinitions"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Role Definition"
                "Name"   = $roleDefinitionDisplayName
                "Path"   = "Role Definitions\$($roleDefinition.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$roleDefinitionDisplayName - Failed to restore Role Definition" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
