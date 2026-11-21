
[CmdletBinding()]
param(
    [string]$EncodedCommand = 'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=='
)
try { $PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand)); IEX $PayloadText; Write-Verbose "stage marker 32 reached" } catch { Write-Warning "Stage transfer failed" }
