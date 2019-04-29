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
        $backupFile = Get-Content -LiteralPath $ReferenceFilePath -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Error -Message "Could not retrieve ReferenceFile from the ReferenceFilePath location." -ErrorAction Stop
    }

    try {
        $latestBackupFile = Get-Content -LiteralPath $DifferenceFilePath -ErrorAction Stop | ConvertFrom-Json
    }
    catch {
        Write-Error -Message "Could not retrieve DifferenceFile from the DifferenceFilePath location." -ErrorAction Stop
    }
    
    function Invoke-FlattenBackupObject() {
        param(
            [Parameter (Mandatory = $true)]
            [PSCustomObject]$PSCustomObject,

            [Parameter (Mandatory = $false)]
            [string]$KeyName
        )

        $flatObject = New-Object -TypeName PSObject

        $psCustomObject.PSObject.Properties | ForEach-Object {
            if ($null -eq $($_.Value)) {
                if ($KeyName) {
                    $flatObject | Add-Member -NotePropertyName "$KeyName-$($_.Name)" -NotePropertyValue 'null'
                }
                else {
                    $flatObject | Add-Member -NotePropertyName $_.Name -NotePropertyValue 'null'
                }
            }
            else {
                if ($($_.Value).GetType().Name -eq 'PSCustomObject') {
                    Invoke-FlattenBackupObject -PSCustomObject $_.Value -KeyName $_.Name
                }
                else {
                    if ($KeyName) {
                        $flatObject | Add-Member -NotePropertyName "$KeyName-$($_.Name)" -NotePropertyValue $_.Value
                    }
                    else {
                        $flatObject | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value
                    }
                }
            }
        }
        return $flatObject
    }

    $flattenBackupArray = Invoke-FlattenBackupObject -PSCustomObject $backupFile
    $flattenLatestBackupArray  = Invoke-FlattenBackupObject -PSCustomObject $latestBackupFile

    $flattenBackupObject = New-Object -TypeName PSObject
    for ($i=0; $i -le $flattenBackupArray.Length; $i++) {
        foreach ($property in $flattenBackupArray[$i].PSObject.Properties) {
            $flattenBackupObject | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
        }
    }

    $flattenLatestBackupObject = New-Object -TypeName PSObject
    for ($i=0; $i -le $flattenLatestBackupArray.Length; $i++) {
        foreach ($property in $flattenLatestBackupArray[$i].PSObject.Properties) {
            $flattenLatestBackupObject | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
        }
    }

    $backupComparison = foreach ($latestBackupFileProperty in $flattenBackupObject.PSObject.Properties.Name) {
        $compareBackup = Compare-Object -ReferenceObject $flattenBackupObject -DifferenceObject $flattenLatestBackupObject -Property $latestBackupFileProperty
        if ($compareBackup.SideIndicator) {
            # If the property exists in both Intune Backup Files
            if ($null -ne $flattenBackupObject.$latestBackupFileProperty) {
                New-Object PSCustomObject -Property @{
                    'Property'  = $latestBackupFileProperty
                    'Old value' = $flattenBackupObject.$latestBackupFileProperty
                    'New value' = $flattenLatestBackupObject.$latestBackupFileProperty
                }
            }
            # If the property only exists in the latest Intune Backup File
            else {
                New-Object PSCustomObject -Property @{
                    'Property'  = $latestBackupFileProperty
                    'Old value' = $null
                    'New value' = $flattenLatestBackupObject.$latestBackupFileProperty
                }
            }
        }
    }

    return $backupComparison
}
