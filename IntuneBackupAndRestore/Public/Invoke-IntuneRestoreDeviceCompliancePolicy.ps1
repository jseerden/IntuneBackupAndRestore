function Invoke-IntuneRestoreDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Restore Intune Device Compliance Policies
    
    .DESCRIPTION
    Restore Intune Device Compliance Policies from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceCompliancePolicy function
    
    .EXAMPLE
    Invoke-IntuneRestoreDeviceCompliance -Path "C:\temp" -RestoreById $true
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
        connect-mggraph -scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All" 
    }

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Get-ChildItem -Path "$Path\Device Compliance Policies" -File -ErrorAction SilentlyContinue
	
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $deviceCompliancePolicyContent = Get-Content -LiteralPath $deviceCompliancePolicy.FullName  -Raw | ConvertFrom-Json

        $deviceCompliancePolicyDisplayName = $deviceCompliancePolicyContent.displayName

        # Remove properties that are not available for creating a new configuration
        $requestBody = $deviceCompliancePolicyContent | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime 

        # If missing, adds a default required block scheduled action to the compliance policy request body, as this value is not returned when retrieving compliance policies.
        if (-not ($requestBody.scheduledActionsForRule)) {
            $scheduledActionsForRule = @(
                @{
                    ruleName = "PasswordRequired"
                    scheduledActionConfigurations = @(
                        @{
                            actionType = "block"
                            gracePeriodHours = 0
                            notificationTemplateId = ""
                        }
                    )
                }
            )
            $requestBody | Add-Member -NotePropertyName scheduledActionsForRule -NotePropertyValue $scheduledActionsForRule
        }
        
        $requestBodyJson = $requestBody | ConvertTo-Json -Depth 100

        # Restore the Device Compliance Policy
        try {
            $null = Invoke-MgGraphRequest -Method POST -body $requestBodyJson.toString() -Uri "beta/deviceManagement/deviceCompliancePolicies" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Compliance Policy"
                "Name"   = $deviceCompliancePolicyDisplayName
                "Path"   = "Device Compliance Policies\$($deviceCompliancePolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceCompliancePolicyDisplayName - Failed to restore Device Compliance Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}
