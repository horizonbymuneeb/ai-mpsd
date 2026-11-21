
[CmdletBinding()]
param(
    [int]$TimeoutSec = 99
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

$ProgressPreference = "SilentlyContinue"
