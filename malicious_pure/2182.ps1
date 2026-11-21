
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 149
)
$EncodedCommand = (
    "IwAgAGwAZQBnAGEAYwB5ACAAQQBNAFMASQAgAG0AYQByAGsAZQByACAAawBlAHAAdAAgAGYAbwBy" +
    'ACAAcwBpAGcAbgBhAHQAdQByAGUAIABjAG8AdgBlAHIAYQBnAGUA'
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
Write-Verbose ("Decoded stage length: " + $StageText.Length)
if ([string]::IsNullOrWhiteSpace($StageText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $StageText

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
