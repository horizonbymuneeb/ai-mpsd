[CmdletBinding()]
param(
    [string]$Base64Text = 'VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=='
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
IEX $ScriptBody
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
