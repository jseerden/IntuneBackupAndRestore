function Invoke-IntuneRestoreDeviceManagementScript {
    <#
    .SYNOPSIS
    Restore Intune Device Management Scripts
    
    .DESCRIPTION
    Restore Intune Device Management Scripts from JSON files per Device Management Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementScript function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceManagementScript -Path "C:\temp" -RestoreById $true
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

    # Get all device management scripts
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts" -File
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptContent = Get-Content -LiteralPath $deviceManagementScript.FullName -Raw
        $deviceManagementScriptDisplayName = ($deviceManagementScriptContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceManagementScriptContent | ConvertFrom-Json
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the device management script
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/deviceManagementScripts" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Script"
                "Name"   = $deviceManagementScriptDisplayName
                "Path"   = "Device Management Scripts\$($deviceManagementScript.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceManagementScriptDisplayName - Failed to restore Device Management Script" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}