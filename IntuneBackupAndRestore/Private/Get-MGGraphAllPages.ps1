function Get-MGGraphAllPages {
    <#
    .SYNOPSIS
    Retrieve all pages of a Microsoft Graph Query
    
    .DESCRIPTION
    Retrieve all pages of a Microsoft Graph Query
    
    .PARAMETER GraphResults
    Microsoft Graph Query Results
    
    .EXAMPLE
    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations" | Get-MGGraphAllPages
    
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]$GraphResults
    )
    $uri = $null
    $QueryResults = @()
    do {
        if($uri){$GraphResults = Invoke-MgGraphRequest -uri "$uri"}
        if ($GraphResults.value) {
            $QueryResults += $GraphResults.value
        }
        else {
            $QueryResults += $GraphResults
        }
        $uri = $GraphResults.'@odata.nextlink'
    } until (!($uri))

    #Check for null Value
    if(($QueryResults.count -eq 2) -and ([string]::IsNullOrEmpty($QueryResults.value)) -and ($QueryResults.'@odata.context' -match "https://graph.microsoft.com/")) {
        $QueryResults = $null
    }

    return $QueryResults
    
}