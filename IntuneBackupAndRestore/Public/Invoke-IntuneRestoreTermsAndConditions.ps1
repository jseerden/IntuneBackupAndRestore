function Invoke-IntuneRestoreTermsAndConditions {
    <#
    .SYNOPSIS
    Restore Intune Terms and Conditions

    .DESCRIPTION
    Restore Intune Terms and Conditions from JSON files per terms from the specified Path.

    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupTermsAndConditions function

    .PARAMETER ApiVersion
    API version to use (Beta or v1.0). Default is v1.0.

    .EXAMPLE
    Invoke-IntuneRestoreTermsAndConditions -Path "C:\temp"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "v1.0"
    )

    #Connect to MS-Graph if required
    if ($null -eq (Get-MgContext)) {
        connect-mggraph -scopes "DeviceManagementServiceConfig.ReadWrite.All"
    }

    # Get all Terms and Conditions
    $termsAndConditions = Get-ChildItem -Path "$Path\Terms and Conditions" -File -ErrorAction SilentlyContinue

    foreach ($terms in $termsAndConditions) {
        $termsContent = Get-Content -LiteralPath $terms.FullName -Raw | ConvertFrom-Json

        $termsDisplayName = $termsContent.displayName

        # Remove properties that are not available for creating new terms
        $requestBody = $termsContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, acceptanceStatement

        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Terms and Conditions
        try {
            $createdPolicy = Invoke-MgGraphRequest -Method POST -Body $requestBodyJson.toString() -Uri "$ApiVersion/deviceManagement/termsAndConditions"
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Terms and Conditions"
                "Name"   = $termsDisplayName
                "Path"   = "Terms and Conditions\$($terms.Name)"
                "Id"     = $createdPolicy.id
            }
        }
        catch {
            Write-Verbose "$termsDisplayName - Failed to restore Terms and Conditions" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
