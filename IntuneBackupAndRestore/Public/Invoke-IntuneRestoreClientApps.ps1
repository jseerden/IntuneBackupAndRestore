function Invoke-IntuneRestoreClientApps {
    <#
    .SYNOPSIS
    Restore Intune Client Apps
    
    .DESCRIPTION
    Restore Intune Client Apps from JSON files per Client App from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupConfigurationPolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreClientApps -Path "C:\temp"
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

    # Get all Client Apps
    $clientApps = Get-ChildItem -Path "$Path\Client Apps" -File

    foreach ($clientapp in $clientApps) {
        $clientappContent = Get-Content -LiteralPath $clientapp.FullName -Raw | ConvertFrom-Json
        
        # Remove properties that are not available for creating a new configuration
        $requestBody = $clientappContent | Select-Object -Property * -ExcludeProperty "@odata.context", uploadState, publishingState, isAssigned, dependentAppCount, supersedingAppCount, supersededAppCount, id, createdDateTime, lastModifiedDateTime, settingCount, creationSource | ConvertTo-Json -Depth 100

        # Restore the Settings Catalog Policy
        try {
            $null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceAppManagement/mobileApps" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Client App"
                "Name"   = $clientapp.FullName
                "Path"   = "Client Apps\$($clientapp.Name)"
            }
        }
        catch {
            Write-Verbose "$($clientapp.FullName) - Failed to restore Client App" -Verbose
            Write-Error $_ -ErrorAction Continue
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $ErrResp = $streamReader.ReadToEnd() | ConvertFrom-Json
        $streamReader.Close()
        }
        $ErrResp
    }
}

Invoke-IntuneRestoreClientApps -Path C:\IntuneBackup\