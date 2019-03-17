function Compare-IntuneBackupFile() {
    <#
    .SYNOPSIS
    Compare two Intune Backup Files for changes.
    
    .DESCRIPTION
    Compare two Intune Backup Files for changes.
    
    .PARAMETER ReferenceFilePath
    Any Intune Backup file.
    
    .PARAMETER DifferenceFilePath
    Latest Intune Backup file, that matches the Intune Configuration (e.g. Device Compliance Policy, Device Configuration Profile or Device Management Script).
    
    .EXAMPLE
    Compare-IntuneBackupFile -ReferenceFilePath 'C:\temp\IntuneBackup\Device Configurations\Windows - Endpoint Protection.json' -DifferenceFilePath 'C:\temp\IntuneBackupLatest\Device Configurations\Windows - Endpoint Protection.json'
    
    .NOTES
    The DifferenceFilePath should point to the latest Intune Backup file, as it might contain new properties.
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReferenceFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DifferenceFilePath
    )

    try {
        $backupFile = Get-Content -Path $ReferenceFilePath -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Error -Message "Could not retrieve ReferenceFile from the ReferenceFilePath location." -ErrorAction Stop
    }

    try {
        $latestBackupFile = Get-Content -Path $DifferenceFilePath -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Error -Message "Could not retrieve DifferenceFile from the DifferenceFilePath location." -ErrorAction Stop
    }

    $backupComparison = foreach ($latestBackupFileProperty in $latestBackupFile.PSObject.Properties.Name) {
        $compareBackup = Compare-Object -ReferenceObject $backupFile -DifferenceObject $latestBackupFile -Property $latestBackupFileProperty
        if ($compareBackup.SideIndicator) {
            # If the property exists in both Intune Backup Files
            if ($backupFile.$latestBackupFileProperty) {
                New-Object PSCustomObject -Property @{
                    'Property'  = $latestBackupFileProperty
                    'Old value' = $backupFile.$latestBackupFileProperty
                    'New value' = $latestBackupFile.$latestBackupFileProperty
                }
            }
            # If the property only exists in the latest Intune Backup File
            else {
                New-Object PSCustomObject -Property @{
                    'Property'  = $latestBackupFileProperty
                    'Old value' = $null
                    'New value' = $latestBackupFile.$latestBackupFileProperty
                }
            }
        }
    }

    return $backupComparison
}
