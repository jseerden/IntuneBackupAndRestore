Function Compare-IntuneBackupDirectories
{
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
	
	Param (
		[parameter(Mandatory = $true, Position = 0)]
		[String]$ReferenceDirectory,
		[parameter(Mandatory = $true, Position = 1)]
		[String]$DifferenceDirectory
		
	)
	Begin
	{
		$ReferenceFiles = Get-ChildItem $ReferenceDirectory -Recurse | Where-Object { $_.Name -like "*.json*" } | Select-Object -ExpandProperty VersionInfo
		
		$DifferenceFiles = Get-ChildItem $DifferenceDirectory -Recurse | Where-Object { $_.Name -like "*.json*" } | Select-Object @{ Label = "FileName"; Expression = { (($_.VersionInfo).FileName).split("\") | Select-Object -Last 1 } }, @{ Label = "FullPath"; Expression = { (($_.VersionInfo).FileName) } }
	}
	Process
	{
		Foreach ($File in $ReferenceFiles)
		{
			$ReferenceJSONFile = ($File.Filename).split("\") | Select-Object -last 1
			
			Write-Verbose "The reference file is '$ReferenceJSONFile'"
			Write-Verbose "The reference file path is $($File.FileName)"
			
			$DifFileFound = $DifferenceFiles | Where-Object { $_.FileName -eq $ReferenceJSONFile }
			
			If (($DifFileFound.FileName).count -gt 1)
			{
				$ReferenceJSONFile = ($File.Filename).split("\") | Select-Object -last 2
				$ReferenceJSONFileParent = ($File.FileName).split("\") | Select-Object -Last 2
				$ReferenceJSONFileParentPath = "$(($ReferenceJSONFileParent).item(0))\$(($ReferenceJSONFileParent).item(1))"
				Write-Verbose "Multiple difference files found that were matching the reference file"
				$DifFileFound = $DifferenceFiles | Where-Object { $_.FullPath -like "*$ReferenceJSONFileParentPath*" }
			}
			
			Write-Verbose "The difference file is located at $($DifFileFound.fullpath)"
			
			Write-Verbose "Checking for changes in the file '$ReferenceJSONFile'"
			
			$Changes = Compare-IntuneBackupFile -ReferenceFilePath $File.FileName -DifferenceFilePath $DifFileFound.FullPath -ErrorAction silentlycontinue
			If ($Changes)
			{
				Write-Host "There was a change in the file, '$ReferenceJSONFile' which is located at $($DifFileFound.fullpath)"
				$Changes | Format-Table -AutoSize
			}
		}
	}
}
