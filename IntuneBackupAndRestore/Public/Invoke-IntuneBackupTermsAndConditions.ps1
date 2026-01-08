function Invoke-IntuneBackupTermsAndConditions {
    <#
    .SYNOPSIS
    Backup Intune Terms and Conditions

    .DESCRIPTION
    Backup Intune Terms and Conditions as JSON files per policy to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is Beta.

    .EXAMPLE
    Invoke-IntuneBackupTermsAndConditions -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get all Terms and Conditions
    $termsAndConditions = Invoke-MgGraphRequest -Uri "$ApiVersion/deviceManagement/termsAndConditions" | Get-MGGraphAllPages

    if ($termsAndConditions -and $termsAndConditions.Count -gt 0) {

        # Create folder if not exists
        if (-not (Test-Path "$Path\Terms and Conditions")) {
            $null = New-Item -Path "$Path\Terms and Conditions" -ItemType Directory
        }

        foreach ($termsAndCondition in $termsAndConditions) {
            # Skip if displayName is null or empty
            if ([string]::IsNullOrEmpty($termsAndCondition.displayName)) {
                Write-Warning "Skipping Terms and Conditions with null or empty displayName (ID: $($termsAndCondition.id))"
                continue
            }

            # Use ConvertTo-SafeFilename if available, otherwise fallback to Split
            if (Get-Command ConvertTo-SafeFilename -ErrorAction SilentlyContinue) {
                $fileName = ConvertTo-SafeFilename -FileName $termsAndCondition.displayName
            } else {
                $fileName = ($termsAndCondition.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            }

            $termsAndCondition | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$Path\Terms and Conditions\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Terms and Conditions"
                "Name"   = $termsAndCondition.displayName
                "Path"   = "Terms and Conditions\$fileName.json"
            }
        }
    }
}
