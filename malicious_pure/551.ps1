
# Remote staging
$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpkeHZlMHBnb2R4")
Write-Verbose ("Assembly bytes: " + $AssemblyBytes.Length)
[Reflection.Assembly]::Load($AssemblyBytes)
$StageMarker = "stage-33"
Write-Verbose "stage marker 32 reached"
