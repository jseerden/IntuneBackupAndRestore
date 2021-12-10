function Compare-IntuneBackupDirectories() {
	<#
    .SYNOPSIS
    Compare two Intune Backup Directories for changes in each of their JSON backup files.

    .DESCRIPTION
    Compare two Intune Backup Directories for changes.

    .PARAMETER $ReferenceDirectory
    Any Intune Backup Directory.

    .PARAMETER $DifferenceDirectory
    Latest Intune Backup directory

    .EXAMPLE
	- Show verbose output
    Compare-IntuneBackupDirectories -Verbose -ReferenceDirectory C:\Users\BradleyWyatt\AppData\Local\Temp\IntuneBackup -DifferenceDirectory C:\Users\BradleyWyatt\AppData\Local\Temp\IntuneNewBackup

	Compare-IntuneBackupDirectories -ReferenceDirectory C:\Users\BradleyWyatt\AppData\Local\Temp\IntuneBackup -DifferenceDirectory C:\Users\BradleyWyatt\AppData\Local\Temp\IntuneNewBackup

    .NOTES
    Requires the IntuneBackupAndRestore Module

	.AUTHOR
	Bradley Wyatt - The Lazy Administrator
    #>

	param (
		[parameter(Mandatory = $true, Position = 0)]
		[String]$ReferenceDirectory,
		[parameter(Mandatory = $true, Position = 1)]
		[String]$DifferenceDirectory
	)

	begin {
		$referenceFiles = Get-ChildItem $ReferenceDirectory -Recurse | Where-Object { $_.Name -like "*.json*" } | Select-Object -ExpandProperty VersionInfo

		$differenceFiles = Get-ChildItem $DifferenceDirectory -Recurse | Where-Object { $_.Name -like "*.json*" } | Select-Object @{ Label = "FileName"; Expression = { (($_.VersionInfo).FileName).split("\") | Select-Object -Last 1 } }, @{ Label = "FullPath"; Expression = { (($_.VersionInfo).FileName) } }
	}

	process	{
		foreach ($file in $referenceFiles) {
			$referenceJSONFile = ($file.Filename).split("\") | Select-Object -last 1

			Write-Verbose "The reference file is '$referenceJSONFile'"
			Write-Verbose "The reference file path is $($file.FileName)"

			$difFileFound = $differenceFiles | Where-Object { $_.FileName -eq $referenceJSONFile }

			if (($difFileFound.FileName).count -gt 1) {
				$referenceJSONFile = (($file.Filename).split("\") | Select-Object -last 2) -join "\"
				$referenceJSONFileParent = ($file.FileName).split("\") | Select-Object -Last 2
				$referenceJSONFileParentPath = $referenceJSONFileParent -join "\"
				Write-Verbose "Multiple difference files found that were matching the reference file"
				$difFileFound = $differenceFiles | Where-Object { $_.FullPath -like "*$referenceJSONFileParentPath*" }
				if (($difFileFound.FileName).count -gt 1) {
					# path wasn't precise enough to uniquely identify the correct difference file
					# try to use last three parts of the file path instead of two
					$referenceJSONFileParent = ($file.FileName).split("\") | Select-Object -Last 3
					$referenceJSONFileParentPath = $referenceJSONFileParent -join "\"
					Write-Verbose "Multiple difference files found again that were matching the reference file"
					$difFileFound = $differenceFiles | Where-Object { $_.FullPath -like "*$referenceJSONFileParentPath*" }
					if (($difFileFound.FileName).count -gt 1) {
						Write-Warning "Unable to uniquely identify difference file. Skipping $referenceJSONFile"
						continue
					}
				}
			}

			Write-Verbose "The difference file is located at $($difFileFound.fullpath)"

			Write-Verbose "Checking for changes in the file '$referenceJSONFile'"

			$changes = Compare-IntuneBackupFile -ReferenceFilePath $file.FileName -DifferenceFilePath $difFileFound.FullPath -ErrorAction "Continue"
			if ($changes) {
				Write-Output "There was a change in the file, '$referenceJSONFile' which is located at $($difFileFound.fullpath)"
				$changes | Format-Table -AutoSize
			}
		}

		# search for new settings that doesn't exist in first backup
		foreach ($file in $differenceFiles) {
			$differenceJSONFile = $file.Filename

			Write-Verbose "The difference file is '$differenceJSONFile'"
			Write-Verbose "The difference file path is $($file.FullPath)"

			$difFileFound = $referenceFiles | Where-Object { (($_.FileName).split("\") | Select-Object -Last 1) -eq $differenceJSONFile }

			if (($difFileFound.FileName).count -gt 1) {
				$differenceJSONFileParent = ($file.FullPath).split("\") | Select-Object -Last 2
				$differenceJSONFileParentPath = $differenceJSONFileParent -join "\"
				Write-Verbose "Multiple reference files found that were matching the difference file"
				$difFileFound = $referenceFiles | Where-Object { $_.FileName -like "*$differenceJSONFileParentPath*" }
				if (($difFileFound.FileName).count -gt 1) {
					# filter wasn't precise enough to uniquely identify the correct difference file
					# try to use last three parts of the file path instead of two
					$differenceJSONFileParent = ($file.FullPath).split("\") | Select-Object -Last 3
					$differenceJSONFileParentPath = $differenceJSONFileParent -join "\"
					Write-Verbose "Multiple reference files found again that were matching the difference file"
					$difFileFound = $referenceFiles | Where-Object { $_.FileName -like "*$differenceJSONFileParentPath*" }
					if (($difFileFound.FileName).count -gt 1) {
						Write-Warning "Unable to uniquely identify difference file. Skipping $differenceJSONFile"
						continue
					}
				}
			}

			if (!$difFileFound) {
				Write-Output "There is a new file. '$differenceJSONFile' which is located at $($file.FullPath)"
			}
		}
	}
}
