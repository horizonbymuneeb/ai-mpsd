
[CmdletBinding()]
param(
    [int]$TimeoutSec = 136
)
$EncodedCommand = (
    "VwByAGkAdABlAC0ATwB1AHQAcAB1AHQAIAAiAHMAdABhAGcAZQAgAHIAZQBhAGQAeQAiAA=="
)
$ScriptBody = [Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($EncodedCommand))
Write-Verbose ("Decoded stage length: " + $ScriptBody.Length)
if ([string]::IsNullOrWhiteSpace($ScriptBody)) {
    throw "Decoded stage was empty"
}
Invoke-Expression $ScriptBody

$StageMarker = "stage-34"
