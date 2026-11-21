
[CmdletBinding()]
param(
    [string]$ScriptPayload = 'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAZQBuAGMAbwBkAGUAZAAgAHMAdABhAGcAZQAgAGMAbwBtAHAAbABlAHQAZQAiAA=='
)
try { $PayloadText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ScriptPayload)); IEX $PayloadText; $Host.UI.RawUI.WindowTitle = "Windows Update" } catch { Write-Warning "Stage transfer failed" }
