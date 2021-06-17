function Invoke-IntuneBackupDeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Management Script Assignments
    
    .DESCRIPTION
    Backup Intune Device Management Script Assignments as JSON files per Device Management Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceManagementScriptAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Management Scripts\Assignments")) {
        $null = New-Item -Path "$Path\Device Management Scripts\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $deviceManagementScripts = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceManagementScripts" | Get-MSGraphAllPages

    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceManagementScripts/$($deviceManagementScript.id)/assignments" | Get-MSGraphAllPages
        
        if ($assignments) {
            $fileName = ($deviceManagementScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Scripts\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Management Script Assignments"
                "Name"   = $deviceManagementScript.displayName
                "Path"   = "Device Management Scripts\Assignments\$fileName.json"
            }
        }
    }
}