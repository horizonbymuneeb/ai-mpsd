<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 41
)
$EncodedCommand = (
    'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAg' +
    'AGMAbwBtAHAAbABlAHQAZQAiAA=='
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
Write-Verbose ("Decoded stage length: " + $PayloadText.Length)
if ([string]::IsNullOrWhiteSpace($PayloadText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $PayloadText

$Host.UI.RawUI.WindowTitle = "Windows Update"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
