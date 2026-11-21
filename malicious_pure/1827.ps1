[CmdletBinding()]
param(
    [string]$EncodedCommand = "VwByAGkAdABlAC0AVgBlAHIAYgBvAHMAZQAgACIAcwB0AGEAZwBlACAAbwBuAGUAIABsAG8AYQBkAGUAZAAiAA=="
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
IEX $DecodedText
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
