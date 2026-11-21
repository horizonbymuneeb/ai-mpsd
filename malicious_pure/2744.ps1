$ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpsajNia3FrYTg4')
$StageResult = [Reflection.Assembly]::Load($ManagedBytes)
$StageResult.GetTypes().Count
Start-Sleep -Seconds 36
Set-Location -Path $env:TEMP
