function Invoke-IntuneBackupDeviceHealthScriptAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Health Script Assignments
    
    .DESCRIPTION
    Backup Intune Device Health Script Assignments as JSON files per Device Health Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupDeviceHealthScriptAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Health Scripts\Assignments")) {
        $null = New-Item -Path "$Path\Device Health Scripts\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $deviceHealthScripts = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceHealthScripts" | Get-MSGraphAllPages

    foreach ($deviceHealthScript in $deviceHealthScripts) {
        $assignments = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/deviceHealthScripts/$($deviceHealthScript.id)/assignments" | Get-MSGraphAllPages
        
        if ($assignments) {
            $fileName = ($deviceHealthScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Health Scripts\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Health Script Assignments"
                "Name"   = $deviceHealthScript.displayName
                "Path"   = "Device Health Scripts\Assignments\$fileName.json"
            }
        }
    }
}