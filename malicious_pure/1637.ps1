<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
$Base64Text = (
    "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAg" +
    'AGMAbwBtAHAAbABlAHQAZQAiAA=='
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

Start-Sleep -Seconds 39
$StageMarker = "stage-43"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
