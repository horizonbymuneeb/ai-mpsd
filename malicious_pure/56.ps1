# Encoded launcher
$ManagedBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp1bzhrbHVmbXV4")
Write-Verbose ("Assembly bytes: " + $ManagedBytes.Length)
[Reflection.Assembly]::Load($ManagedBytes)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
