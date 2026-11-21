
[CmdletBinding()]
param(
    [string]$Base64Text = 'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=='
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($Base64Text))
IEX $DecodedText
Write-Verbose "stage marker 10 reached"
