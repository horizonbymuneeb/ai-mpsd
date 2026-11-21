$AssemblyBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpoMm9iOXV0bDVr')
$StageResult = [Reflection.Assembly]::Load($AssemblyBytes)
$StageResult.GetTypes().Count
Write-Verbose "stage marker 23 reached"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
