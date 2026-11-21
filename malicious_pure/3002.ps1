
try { [ScriptBlock]::Create([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("U3RhcnQtU2xlZXAgLU1pbGxpc2Vjb25kcyAzNzM7IFdyaXRlLVZlcmJvc2UgInN0YWdlIGRlbGF5IGZpbmlzaGVkIg=="))).Invoke(); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Set-Location -Path $env:TEMP } catch { Write-Warning "Stage transfer failed" }
