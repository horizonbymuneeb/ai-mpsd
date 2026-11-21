
$StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp1ODkwejI5YmNp'); $OperationResult = [Reflection.Assembly]::Load($StageBytes); $OperationResult.GetTypes().Count; Set-Location -Path $env:TEMP; Start-Sleep -Seconds 31
