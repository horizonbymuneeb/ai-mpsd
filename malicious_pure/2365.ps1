
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\payload.ps1
#>
$Base64Text = (
    "UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADcAOQA5" +
    'ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkA' +
    "IABmAGkAbgBpAHMAaABlAGQAIgA="
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $ScriptBody

Write-Output "stage 24 initialized"
