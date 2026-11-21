<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$ScriptPayload = "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=="
)
$StageText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($ScriptPayload))
IEX $StageText
$ProgressPreference = "SilentlyContinue"
