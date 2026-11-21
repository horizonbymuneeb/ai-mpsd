
[CmdletBinding()]
param(
    [int]$TimeoutSec = 134
)
$EncodedStage = (
    'VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=='
)
$DecodedText = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedStage))
Write-Verbose ("Decoded stage length: " + $DecodedText.Length)
if ([string]::IsNullOrWhiteSpace($DecodedText)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $DecodedText

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Set-Location -Path $env:TEMP
