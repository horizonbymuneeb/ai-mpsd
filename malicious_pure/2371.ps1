
try { [ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('V3JpdGUtVmVyYm9zZSAic3RhZ2Ugb25lIGxvYWRlZCI='))).Invoke(); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Stage transfer failed" }
