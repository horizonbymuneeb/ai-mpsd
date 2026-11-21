[CmdletBinding()]
param(
    [string]$Base64Text = "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
IEX $ScriptBody
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
