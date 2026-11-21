[CmdletBinding()]
param(
    [int]$TimeoutSec = 159
)
$Base64Text = (
    "UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADgANgA4" +
    'ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkA' +
    'IABmAGkAbgBpAHMAaABlAGQAIgA='
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
try {
    Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
    if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $ScriptBody
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
