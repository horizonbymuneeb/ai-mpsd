
<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$TargetUrl = "https://localhost:8000/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpkOHdyY210Ynhn")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 18 reached"
$StageMarker = "stage-23"
