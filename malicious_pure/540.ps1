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
    [int]$TimeoutSec = 12
)
$EncodedStage = (
    "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBk" +
    'AGUAZAAiAA=='
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
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
