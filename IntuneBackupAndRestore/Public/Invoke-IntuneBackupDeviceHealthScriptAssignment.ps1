function Invoke-IntuneBackupDeviceHealthScriptAssignment {
    <#
    .SYNOPSIS
    Backup Intune Health Script (remediation Scripts) Assignments

    .DESCRIPTION
    Backup Intune Health Script (remediation Scripts) Assignments as JSON files per Health Script Policy to the specified Path.

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

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Health Scripts\Assignments")) {
        $null = New-Item -Path "$Path\Device Health Scripts\Assignments" -ItemType Directory
    }

    $healthScripts = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/$ApiVersion/deviceManagement/deviceHealthScripts" | Select-Object -ExpandProperty Value

    foreach ($healthScript in $healthScripts) {
        $assignments = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/$ApiVersion/deviceManagement/deviceHealthScripts/$($healthScript.id)/assignments"

        if ($assignments) {
            $fileName = ($healthScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Health Scripts\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Health Scripts Assignments"
                "Name"   = $healthScript.displayName
                "Path"   = "Device Health Scripts\Assignments\$fileName.json"
            }
        }
    }
}