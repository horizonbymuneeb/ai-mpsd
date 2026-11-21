
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\updater.ps1
#>
$Base64Text = (
    "UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBNAGkAbABsAGkAcwBlAGMAbwBuAGQAcwAgADUAMAA5" +
    "ADsAIABXAHIAaQB0AGUALQBWAGUAcgBiAG8AcwBlACAAIgBzAHQAYQBnAGUAIABkAGUAbABhAHkA" +
    "IABmAGkAbgBpAHMAaABlAGQAIgA="
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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Write-Verbose "stage marker 20 reached"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
