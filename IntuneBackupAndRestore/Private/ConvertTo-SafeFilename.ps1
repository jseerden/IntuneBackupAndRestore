function ConvertTo-SafeFilename {
    <#
    .SYNOPSIS
    Converts a string to a safe filename for cross-platform compatibility

    .DESCRIPTION
    Removes or replaces invalid characters for both Windows and Unix-based filesystems.
    Handles Windows invalid chars, Unix special chars, and additional problematic characters.

    .PARAMETER FileName
    The filename string to sanitize

    .PARAMETER Replacement
    The character to use as replacement for invalid characters (default: '_')

    .EXAMPLE
    ConvertTo-SafeFilename -FileName "My Policy: Test (v1.0)"
    Returns: "My_Policy_Test_v1.0"

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string]$Replacement = '_'
    )

    # Get Windows invalid filename characters
    $invalidChars = [IO.Path]::GetInvalidFileNameChars()

    # Additional characters that can cause issues on Unix/Linux systems
    # Including: colon, asterisk, question mark, quotes, pipes, angle brackets
    $additionalInvalidChars = @(':', '*', '?', '"', "'", '<', '>', '|', '/', '\')

    # Combine all invalid characters
    $allInvalidChars = $invalidChars + $additionalInvalidChars | Select-Object -Unique

    # Escape special regex characters
    $escapedChars = $allInvalidChars | ForEach-Object { [regex]::Escape($_) }

    # Create regex pattern
    $pattern = "[$($escapedChars -join '')]"

    # Replace invalid characters
    $safeName = $FileName -replace $pattern, $Replacement

    # Remove leading/trailing spaces and dots (problematic on some systems)
    $safeName = $safeName.Trim(' ', '.')

    # Ensure the filename isn't empty after sanitization
    if ([string]::IsNullOrWhiteSpace($safeName)) {
        $safeName = "unnamed_file"
    }

    return $safeName
}
