function Invoke-IntuneBackupClientAppAssignment {
    <#
    .SYNOPSIS
    Backup Intune Client App Assignments
    
    .DESCRIPTION
    Backup Intune Client App  Assignments as JSON files per Client App to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientAppAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Client Apps\Assignments")) {
        $null = New-Item -Path "$Path\Client Apps\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $clientApps = Get-GraphClientApp

    foreach ($clientApp in $clientApps) {
        $assignments = Get-GraphClientAppAssignment -Id $clientApp.id 
        if ($assignments) {
            Write-Output "Backing Up - Client App - Assignments: $($clientApp.displayName)"
            $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Client Apps\Assignments\$($clientApp.id) - $fileName.json"
        }
    }
}