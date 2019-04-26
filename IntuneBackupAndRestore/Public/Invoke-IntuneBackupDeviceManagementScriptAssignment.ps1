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
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Management Scripts\Assignments")) {
        $null = New-Item -Path "$Path\Device Management Scripts\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $deviceManagementScripts = Get-GraphDeviceManagementScript

    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $assignments = Get-GraphDeviceManagementScriptAssignment -Id $deviceManagementScript.id
        if ($assignments) {
            Write-Output "Backing Up - Device Management Script - Assignments: $($deviceManagementScript.displayName)"
            $fileName = ($deviceManagementScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Scripts\Assignments\$fileName.json"
        }
    }
}