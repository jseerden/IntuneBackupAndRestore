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
        [bool]$RestoreById = $false,

        [Parameter(Mandatory = $false)]
        [bool]$ConvertPS1ToScriptContent = $true,

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
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts" -File -Filter *.json
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptContent = Get-Content -LiteralPath $deviceManagementScript.FullName -Raw
        $deviceManagementScriptDisplayName = ($deviceManagementScriptContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceManagementScriptContent | ConvertFrom-Json
        # Use PS1 file in "Script Content" folder
        $ScriptPath = "$Path\Device Management Scripts\Script Content\$deviceManagementScriptDisplayName.ps1"
        if(($ConvertPS1ToScriptContent) -and (Test-Path -Path $ScriptPath))
        {
            $ScriptContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path $ScriptPath -Raw -Encoding UTF8)))
            $requestBodyObject.scriptContent = $ScriptContent

        }
        else {
            Write-Output "ConvertPS1ToScriptContent was set to False or PS1 was not found"
        }
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json

        # Restore the device management script
        try {
            if($RestoreById)
            {$null = Invoke-MSGraphRequest -HttpMethod PATCH -Content $requestBody.toString() -Url "deviceManagement/deviceManagementScripts/$(($deviceManagementScriptContent | ConvertFrom-Json).id)" -ErrorAction Stop}
            else 
            { $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/deviceManagementScripts" -ErrorAction Stop}
            
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