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

     #Connect to MS-Graph if required
     if($null -eq (Get-MgContext)){
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All" 
    }

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MgProfile).name -eq $apiVersion)) {
        Select-MgProfile -Name "beta"
    }
    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Health Scripts\Assignments")) {
        $null = New-Item -Path "$Path\Device Health Scripts\Assignments" -ItemType Directory
    }

    $healthScripts = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts" | Get-MGGraphAllPages

    foreach ($healthScript in $healthScripts) {

        $assignments = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/deviceHealthScripts/$($healthScript.id)/assignments"

        if ($assignments) {
            $fileName = ($healthScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json -depth 100| Out-File -LiteralPath "$path\Device Health Scripts\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Health Scripts Assignments"
                "Name"   = $healthScript.displayName
                "Path"   = "Device Health Scripts\Assignments\$fileName.json"
            }
        }
    }
}