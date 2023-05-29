function Invoke-IntuneBackupClientApp {
    <#
    .SYNOPSIS
    Backup Intune Client Apps
    
    .DESCRIPTION
    Backup Intune Client Apps as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-IntuneBackupClientApp -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )
    Select-MgProfile -Name $ApiVersion
    $url = "https://graph.microsoft.com/$ApiVersion"

    # Create folder if not exists
    if (-not (Test-Path "$Path\Client Apps")) {
        $null = New-Item -Path "$Path\Client Apps" -ItemType Directory
    }

    # Get all Client Apps
    $clientApps = Get-MgDeviceAppManagementMobileApp -All
        
    foreach ($clientApp in $clientApps) {
        $clientAppType = $ClientApp.AdditionalProperties.'@odata.type'.split('.')[-1]
        $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        $clientAppDetails = Invoke-GraphRequest -Method GET -Uri "$url/deviceAppManagement/mobileApps/$($clientApp.Id)" -OutputType JSON | ConvertFrom-Json
        $clientAppDetails | ConvertTo-Json | Out-File -LiteralPath "$path\Client Apps\$($clientAppType)_$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Client App"
            "Name"   = $clientApp.displayName
            "Path"   = "Client Apps\$($clientAppType)_$($fileName).json"
        }
    }
}