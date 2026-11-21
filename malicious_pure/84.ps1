
[CmdletBinding()]
param(
    [string]$ScriptPayload = "UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADEAMAA1ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkAIABmAGkAbgBpAHMAaABlAGQAIgA="
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ScriptPayload))
IEX $PayloadText
Write-Verbose "stage marker 26 reached"
