function Connect-IntuneBackupAndRestore {
    <#
    .SYNOPSIS
    Function to connect to MS Graph with required scopes and obtain a token.
    
    .DESCRIPTION
    Function to connect to MS Graph with required scopes and obtain a token.
    The function can connect using with "User" delegated flow, or "Application" Flow.

    .PARAMETER TenantID
    TenantID of your AzureAD tenant.

    .PARAMETER ClientID
    Application ID of your App Registration.

    .PARAMETER CertificateThumbprint
    Certificate's thumbprint of a valid certificate associated with your App Registration. If parameter is used together with 'ClientSecret' parameter, this parameter will have precedence.

    .PARAMETER ClientSecret
    Client secret of your App Registration. If parameter is used together with 'CertificateThumbprint' parameter, this parameter will be ommited.

    .EXAMPLE
    Connect-MgGraph


    #>
    [CmdletBinding()]
    param (
        [String]$TenantID,
        [String]$ClientID,
        [String]$CertificateThumbprint,
        [String]$ClientSecret
    )
    
    begin {
    }
    
    process {
        try {
            Write-Host "Authenticating to Graph..."
            if ( $clientID -ne '' -and $TenantID -ne '' -and ($CertificateThumbprint -ne '' -or $ClientSecret -ne '')) {
                # Connecting to graph using Azure App Application flow with passed parameters
                Write-host "Connecting to graph with AppId: $ClientID with passed parameters"
                if ($PSBoundParameters.ContainsKey('CertificateThumbprint') ) {
                    Connect-MgGraph -ClientId $ClientID -TenantId $TenantID -CertificateThumbprint $CertificateThumbprint
                }
                elseif ($PSBoundParameters.ContainsKey('ClientSecret') ) {
                    $securedClientSecret = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force
                    $clientCredential = New-Object System.Net.NetworkCredential($ClientID, $securedClientSecret)
                    Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $clientCredential
                }
            }
            else {
                # Connecting to graph with the user account
                Write-host "Connecting to graph with the user context"
                Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementServiceConfig.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All"
            }
        }
        catch {
            Write-Host "Failed to authenticate to MS Graph. Error message: $_"
            return
        }
    }
    
    end {
    }
}